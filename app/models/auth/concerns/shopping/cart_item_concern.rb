##NEED A SEPERATE MODEL THAT IMPLEMENTS IT
module Auth::Concerns::Shopping::CartItemConcern


	extend ActiveSupport::Concern
	
	include Auth::Concerns::Shopping::ProductConcern

	included do 

		embeds_many :instructions, :class_name => "Auth::Work::Instruction", :as => :cart_item_instructions, :cascade_callbacks => true
			
		INDEX_DEFINITION = {
			index_name: Auth.configuration.brand_name.downcase,
			index_options:  {
			        settings:  {
			    		index: Auth::Concerns::EsConcern::AUTOCOMPLETE_INDEX_SETTINGS
				    },
			        mappings: {
			          "document" => Auth::Concerns::EsConcern::AUTOCOMPLETE_INDEX_MAPPINGS
			    }
			}
		}

			

		##PERMITTED
		##the id of the product to which this cart item refers.
		##permitted
		field :product_id, type: String

		##the user id who is buying this product.
		##not permitted
		field :resource_id, type: String
		
		##PERMITTED
		
		##not permitted
		field :parent_id, type: String

		##PERMITTED
		##is it being discounted, can be from 0 -> 100 percent discount
		##not permitted
		field :discount, type: Float

		##PERMITTED
		##discount code to offer discounts
		##permitted
		field :discount_code, type: String


		###################### product status fields ##################
		## one of the stages mentioned below.
		field :accepted, type: Boolean


		################### which payment led to this cart item being accepted

		field :accepted_by_payment_id, type: String

		### a percentage of the total price , at which to accept the order.
		## the current item is accepted only if (price*accept_order_at_percentage_of_price) <= available credit
		field :accept_order_at_percentage_of_price, type: Float, default: 1.00


		#################################################################
		##
		##
		## ATTRIBUTES FOR SYSTEM
		##
		##
		#################################################################
		field :unit_id, type: String
		
		field :personality_id, type: String

		field :place_id, type: String

		## this is set as soon as personality is assigned.
		attr_accessor :personality

		before_destroy do |document|
			
			if !skip_callback?("before_destroy")
				if document.accepted == true
					false
				end
			end
		end

=begin
		after_validation do |document|
			if !skip_callback?("after_validation")
				document.refresh_accepted
			end
		end
=end
		before_validation do |document|
			if !skip_callback?("before_validation")
				document.refresh_accepted
			end
		end


		## this is not done anymore.
		
		validate :user_cannot_change_anything_if_payment_accepted
		# no longer done, create_with_embedded checks for the product
		# existence, and that is the way to create a cart item.
		# and update params don't allow a product id to be passed
		# so we don't do this validation.
		#validate :product_id_exists?

		before_save do |document|
			document.public = "no"
		end

		## first of all how are the instructions copied over from the product to the cart item.
		## that's it, now all the communication instructions are enqueued.
		## next step, get a simple notification to be sent by email, and also by sms -> as soon as the time comes for it to be done.
		after_save do |document|
			#puts "came to after_save document #{document.accepted_changed?}"
			#puts "is it true :#{document.accepted == true}"
			if document.accepted_changed? && document.accepted == true
				#puts "accepted changed."
				document.instructions.each do |instruction|
					#puts "doing instruction: #{instruction.id.to_s}"
					instruction.communications.each do |communication|
						## Test seperately?
						## =>  fuck that.
						#puts "doing communication: #{communication.id.to_s}"
						CommunicationJob.set(wait_until: communication.set_enqueue_at).perform_later({:cart_item_id => document.id.to_s, :instruction_id => instruction.id.to_s, :communication_id => communication.id.to_s})
					end
				end
			end
		end
	end


	module ClassMethods

		

		##used in cart_item_controller_concern#index
		## if there is a resource, will return all cart items with that resource id.
		## if there is no resource, will return all cart items with a nil rsource.
		def find_cart_items(options)
			conditions = {:resource_id => nil, :parent_id => nil}
			conditions[:resource_id] = options[:resource].id.to_s if options[:resource]
			Auth.configuration.cart_item_class.constantize.where(conditions)
		end

	end

	### this is an internal method, cannot be set by admin or anyone, it is done after validation, since it is not necessary for someone to be admin, even the user can call refresh on the record to get the new state of the acceptence.
	## just checks if the accepted by payment id exists, and if yes, then doesnt do anything, otherwise will update the cart item status as false.
	def refresh_accepted
		#puts "CALLED REFRESH accepted-----------------------"
		if self.accepted_by_payment_id

			begin
				payment = Auth.configuration.payment_class.constantize.find(self.accepted_by_payment_id)
				## check if this payment status is approved or not.
				## if the payment status is approved, then dont do anything to the cart item.(we don't retro check payment to cart item.)
				## if the payment status is not approved, then make the cart item accepted as false.
				if (payment.payment_status.nil? || payment.payment_status == 0)
					#puts "FOUND THE PAYMENT STATUS TO BE NIL or 0"
					self.accepted = false
				end
			rescue Mongoid::Errors::DocumentNotFound
				
				self.accepted = false
			end
		end

		## if it doesnt have a cart, then it cannot be accepted.
		if self.parent_id.nil?
			self.accepted = false 
			self.accepted_by_payment_id = nil
		end


		## we should ideally do this in the payment.
		## so that it can actually do what it usually does.
		## we can set say refresh_payment.
		## but it may not pay for everything.
		## but that is the only way through.
		## so if the payment is accepted then the cart_items_accepted will not be triggered.
		## but if we update the first payment, then we can do it.
		## basically take the last payment and update it, force calling the set_cart_items_accepted
		## and suppose they are not successfully accepted, then what about validation errors ?
		## so that will have to be skipped in that case.
	end
	
	## called from payment#update_cart_items_accepted
	## sets accepted to true or false depending on whether the cart has enough credit for the item.
	## does not SAVE.
	def set_accepted(payment,override)
		
		

		if cart_has_sufficient_credit_for_item?(payment.cart) 
			
			## is it already accepted?
			if self.accepted
			
				return true
			else
			
				self.accepted = true
			end
		else	
			self.accepted = false
		end
		
		

		
		
		## so that it doesnt do refresh_cart_item
		self.skip_callbacks = {:before_validation => true}
		
		## this will first call validate 
		self.validate

		## if the accepted is being set as false, then it should be set like that, where it was true?
		## 
		self.accepted_by_payment_id = self.accepted ? payment.id.to_s : nil

		
		## if it hasnt changed, dont query and update anything.
		
		return true unless self.accepted_changed?
		
		if self.errors.full_messages.empty?
			
			doc_after_update = 

			Auth.configuration.cart_item_class.constantize.
			where({
				"$and" => [
					"accepted" => {
						"$nin" => [self.accepted]
					},
					"_id" => BSON::ObjectId(self.id.to_s)
				]
			}).
			find_one_and_update(
				{
					"$set" => {
						"accepted" => self.accepted,
						"accepted_by_payment_id" => self.accepted_by_payment_id
					}
				},
				{
					:return_document => :after
				}
			)

			#puts "the doc after update is:"
			#puts doc_after_update.attributes.to_s

			return false unless doc_after_update
			return false if doc_after_update.accepted != self.accepted
			return true
		else
			return false
		end
	end
	
	## debits an amount from the cart equal to (item_price*accept_order_at_percentage_of_price)
	## the #debit function returns the current cart credit.
	## return true or false depending on whether , after debiting there is any credit left in the cart or not.
	def cart_has_sufficient_credit_for_item?(cart)
		#puts "cart credit is: #{cart.cart_credit}"
		cart_has_credit = cart.debit((self.accept_order_at_percentage_of_price*self.price)) >= 0
		#puts "cart has credit is: #{cart_has_credit.to_s}"
		cart_has_credit
	end

	

	## unsets the cart item , if it has not been accepted upto now.
	## assume that a payment was made, this cart item was updated wth its id as success, but some others were not, so the payment was not saved. but this item has got accepted as true.
	## so whether or not the payment that was made exists, we dont allow the cart to be unset.
	## however in case the signed_in_resource is an admin -> it is allowed to unset the cart, whether the item is already accepted or not.
	## @used_in : cart_concern # add_or_remove
	## @return[Boolean] : result of saving the cart item.
	def unset_cart
		if self.signed_in_resource.is_admin?
			self.parent_id = nil
			self.accepted = nil
			self.accepted_by_payment_id = nil
		else
			if (self.accepted.nil? || self.accepted == false)
				self.parent_id = nil 
				self.accepted = nil
				self.accepted_by_payment_id = nil
			end
		end
		rs = self.save
		puts self.errors.full_messages
		rs
	end


	## assigns a cart and resource, resource_id to the cart_item.
	## @returns : true or false depending on whether the cart item was successfully saved or not.
	## @used_in : cart_controller_concern # add_or_remove
	def set_cart_and_resource(cart)
		return true if self.parent_id
		return false if (owner_matches(cart) == false)
		unless cart.can_accept_item?(self)
			self.errors.add(:parent_id, "the cart cannot accept this cart item, please add it to a new cart.")
			return false
		end
		self.parent_id = cart.id.to_s
		self.personality_id = cart.personality_id
		self.place_id = cart.place_id
		self.accepted = nil
		self.accepted_by_payment_id = nil
		self.save
	end

	#######################################################
	##
	## VALIDATIONS
	##
	#######################################################

	## as long as it is not the accepted_by_payment id that has gone from nil to something, if anything else in the cart_item has changed, and the user is not an admin, and there is an accepted_by_payment id, then the error will be triggered.
	## these conditions are applicable to the gateway payment, or any other payment also.
	## and this has happened because the same item was pushed back in.
	def user_cannot_change_anything_if_payment_accepted
		if !self.signed_in_resource.is_admin?

			## THE USER CAN : UPDATE A PAYMENT TO MAKE THIS CART ITEM ACCEPTED / REJECTED.
			## if the payment status is changing, let it be, because this is an internal updated.

			return if self.new_record?

			

			return if self.accepted_changed? 

			## THE USER CAN REMOVE THE CART ITEM FROM A CART, AS LONG AS IT HAS NOT BEEN ACCEPTED.
			## if the item is being removed from the cart, while it has not yet been accepted.
			return if self.parent_id_changed? && self.parent_id.nil? && (self.accepted.nil? || self.accepted == false)


			## THE USER CAN CHANGE ANY OTHER STUFF ALSO AS LONG AS THE ACCEPTED IS NIL OR FALSE
			return if (self.accepted.nil? || self.accepted == false)


			## THE LAST SITUATION IS WHEN THE ITEM WAS ACCEPTED, AND NOW WE ARE UPDATING IT AS FALSE, AND ALSO THE PAYMENT ID AS NIL, THIS IS ALLOWED, BECAUSE IT IS WHAT HAPPENS IF THE ACCEPTING PAYMENT IS NIL OR ITS STATUS IS NOT APPROVED.



			## otherwise, the updated_by_payment_id, changes only when we are doing a gateway payment or any payment actually.
			self.errors.add(:quantity,"you cannot change this item since payment has already been made")
			# if self.accepted_by_payment_id && self.changed? && !self.new_record? && !(self.accepted_by_payment_id_changed? && self.accepted_by_payment_id_was.nil?)
		end
	end

	def product_id_exists?
		begin
			Auth.configuration.product_class.constantize.find(self.product_id)
		rescue
			self.errors.add(:product_id,"this product id does not exist")
		end
	end

	def product_attributes_to_assign
		["name","price","product_code","instructions"]
	end

	## this is got by multiplying the price of the cart item by the minimum_acceptable at field.
	def minimum_price_required_to_accept_cart_item
		price*accept_order_at_percentage_of_price
	end
 	

	## here need to add this action links to the products.
	## it is basically a form to add a cart item
	## that should be added hereitself.
	## 
	def set_secondary_links
			
		unless self.secondary_links["Remove From Wish List"]
			self.secondary_links["Remove From Wish List"] = {
				:partial => "auth/shopping/cart_items/search_results/remove_item_from_wish_list.html.erb",
				:instance_name_in_locals => "cart_item", 
				:other_locals => {}
			}
		end

		unless self.secondary_links["Check Status"]
			if self.parent_id
				self.secondary_links["Check Status"] = {
					:url => Rails.application.routes.url_helpers.send(Auth::OmniAuth::Path.edit_path(Auth.configuration.cart_item_class),self.id.to_s)
				}
			end
		end

		unless self.secondary_links["Remove Item From Cart"]
			self.secondary_links["Remove Item From Cart"] = {
				:partial => "auth/shopping/cart_items/search_results/remove_item_from_cart.html.erb",
				:instance_name_in_locals => "cart_item", 
				:other_locals => {}
			}
		end
		
		## let me add for cart, personality and place as well.
		unless self.secondary_links["See Other Items in Cart"]
			if self.parent_id
				self.secondary_links["See Other Items In Cart"] = {
					:url => Rails.application.routes.url_helpers.send(Auth::OmniAuth::Path.show_or_update_or_delete_path(Auth.configuration.cart_class),self.parent_id)
				}
			end
		end

	end

	def set_autocomplete_tags
		self.tags = []
		self.tags << "item"
		if self.personality_id
			personality = Auth.configuration.personality_class.constantize.find(self.personality_id)
			personality.add_info(self.tags)
		end
	end

	def set_autocomplete_description
		
		self.autocomplete_description = self.name + " - " + self.description
		
	end

	def set_primary_link
			self.primary_link = Rails.application.routes.url_helpers.send(Auth::OmniAuth::Path.show_or_update_or_delete_path(Auth.configuration.cart_item_class),self.id.to_s)
	end	

	###############################################################
	##
	##
	## STATE MACHINE
	##
	##
	###############################################################
	## called from cart_concern ,and there is indirectly called from the cart_controller after_update, and after_create
	## so i have to give a way to call refresh on the cart
	## so that this method is indirectly called.
	## override it in the app to do custom logic with the item
	def process

	end

	## so when this is assigned the personality will be set.
	def personality_id=(personality_id)
		super(personality_id)
		begin
			## here only for all the embedded docs assign this.
			self.personality = 
			Auth.configuration.personality_class.constantize.find(personality_id) unless self.personality
		rescue
		end
	end

	#################################################################################
	##
	##
	## CREATE EMBEDDED
	##
	##
	#################################################################################
	
	## returns false if there are validation errors
	## returns a document incase the document is persisted.
	## adds an error on _id called "failed to create cart item", if the
	## item could not be created despite there being no validation errors.
	## so checking for false means creation has failed and you can 
	## use the instance you already had to check for the validation errors
	def create_with_embedded(product_id)
		created_document = nil
		product = Auth.configuration.product_class.constantize.find(product_id)
		
		product_clone = product.clone
			
		self.created_at = Time.now
  		self.updated_at = Time.now
			
        create_hash = {
        	"$setOnInsert" => self.attributes
        }	            
        	
        product_attributes_to_assign.each do |attr|
        	if product_clone.send("#{attr}").respond_to? :embedded_in
        		create_hash["$setOnInsert"][attr.to_s] = 
        		product_clone.send("#{attr}").map{|c| c = c.attributes}
        	else
        		create_hash["$setOnInsert"][attr.to_s] = product_clone.send("#{attr}")
        	end
        end

        c = Auth.configuration.cart_item_class.constantize.
		where({
			"$and" => [
				"_id" => BSON::ObjectId(self.id.to_s)
			]
		}).
		find_one_and_update(
			{
				"$setOnInsert" => create_hash["$setOnInsert"]
			},
			{
				:return_document => :after,
				:upsert => true
			}
		)

		c.signed_in_resource = self.signed_in_resource
		c.valid?
  		c.run_callbacks(:save) do 
  			c.run_callbacks(:create) do 

  			end
  		end
  		c.run_callbacks(:after_save)
  		c
	end
end