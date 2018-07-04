##NEED A SEPERATE MODEL THAT IMPLEMENTS IT
module Auth::Concerns::Shopping::CartItemConcern



	extend ActiveSupport::Concern
	
	include Auth::Concerns::Shopping::ProductConcern
	include Auth::Concerns::OwnerConcern
	include Auth::Concerns::EsConcern	


	included do 

		INDEX_DEFINITION = {
			index_options:  {
			        settings:  {
			    		index: {
					        analysis:  {
					            filter:  {
					                nGram_filter:  {
					                    type: "nGram",
					                    min_gram: 2,
					                    max_gram: 20,
					                   	token_chars: [
					                       "letter",
					                       "digit",
					                       "punctuation",
					                       "symbol"
					                    ]
					                }
					            },
					            analyzer:  {
					                nGram_analyzer:  {
					                    type: "custom",
					                    tokenizer:  "whitespace",
					                    filter: [
					                        "lowercase",
					                        "asciifolding",
					                        "nGram_filter"
					                    ]
					                },
					                whitespace_analyzer: {
					                    type: "custom",
					                    tokenizer: "whitespace",
					                    filter: [
					                        "lowercase",
					                        "asciifolding"
					                    ]
					                }
					            }
					        }
				    	}
				    },
			        mappings: {
			          Auth::OmniAuth::Path.pathify(Auth.configuration.cart_item_class) => {
			            properties: {
			            	_all_fields:  {
			            		type: "text",
				            	analyzer: "nGram_analyzer",
				            	search_analyzer: "whitespace_analyzer"
				        	},
			                name: {
			                	type: "keyword",
			                	copy_to: "_all_fields"
			                },
			                price: {
			                	type: "double",
			                	copy_to: "_all_fields"
			                },
			                public: {
			                	type: "keyword"
			                },
			                resource_id: {
			                	type: "keyword",
			                	copy_to: "_all_fields"
			                }
			            }
			        }
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


		before_create do |document|
			document.assign_product_attributes
		end

		

		validate :user_cannot_change_anything_if_payment_accepted
		validate :product_id_exists?

		before_save do |document|
			document.public = "no"
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
		puts "CALLED REFRESH accepted-----------------------"
		if self.accepted_by_payment_id

			begin
				payment = Auth.configuration.payment_class.constantize.find(self.accepted_by_payment_id)
				## check if this payment status is approved or not.
				## if the payment status is approved, then dont do anything to the cart item.(we don't retro check payment to cart item.)
				## if the payment status is not approved, then make the cart item accepted as false.
				if (payment.payment_status.nil? || payment.payment_status == 0)
					puts "FOUND THE PAYMENT STATUS TO BE NIL or 0"
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

			puts "the doc after update is:"
			puts doc_after_update.attributes.to_s

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
		puts "cart credit is: #{cart.cart_credit}"
		cart_has_credit = cart.debit((self.accept_order_at_percentage_of_price*self.price)) >= 0
		puts "cart has credit is: #{cart_has_credit.to_s}"
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
		self.parent_id = cart.id.to_s
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

	## before creating the document assigns attributes defined in the def #product_attributes_to_assign, to the cart item.
	def assign_product_attributes
		begin
			if self.product_id
	 			if product = Auth.configuration.product_class.constantize.find(product_id)
	 				product_attributes_to_assign.each do |attr|
	 					## only if the present attribute is nil, then we assign it from the product.
	 					if self.respond_to? attr.to_sym
		 					if self.send("#{attr}").nil?
		 						self.send("#{attr}=",product.send("#{attr}"))
		 					end
	 					end
	 				end
	 			end
	 		end
	 	rescue

	 	end
	end

	def product_attributes_to_assign
		["name","price","bunch"]
	end

	## this is got by multiplying the price of the cart item by the minimum_acceptable at field.
	def minimum_price_required_to_accept_cart_item
		price*accept_order_at_percentage_of_price
	end

	def as_indexed_json(options={})
	 {
	 	name: name,
	    price: price,
	    resource_id: resource_id,
	    public: public
	 }
	end 

=begin
	## @param[String] req : the requirement from the definition. It consists of "*" wildcard, or a product id, or a definition address + product_id -> which is basically one of the output products of the definition. But here it will have the product id, not the self id.
	## it has to be the product id.
	## @return[Boolean] : true/false if this product satisfies the requirement or not.
	## from where is this to be called ?
	## see first we grouped it by the value for that definition.
	## now the question is , that how many things are needed ?
	## is this even necessary?
	## does it need an output address ?
	## i don't think this is needed.
	## we are just going to make the groups.
	## that's where all this will be synchronized
	def satisfies_requirement(req)
		if ((req == self.product_id.to_s) || (req == "*"))
			true
		elsif req == (self.miscellaneous_attributes[:address] + ":" + self.product_id.to_s)
			true
		else
			false
		end
	end
=end

end