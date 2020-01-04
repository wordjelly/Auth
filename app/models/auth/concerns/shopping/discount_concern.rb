=begin

### sample discount object:

id : whatever
product_ids : []
count : 123
needs_verification : true/false
discount_percentage : 
discount_amount :
origin_cart_id : whatever
pending_verification : [cart_id => date_time]
used_by : [cart_id => date/time]

other_fields will be added from owner_concern.

*if both percentage and amount are present, then amount will be used.

*when a payment is made => check if cart fully paid => show option to create coupons,enter discount amount/percentage,enter needs verification or not => if yes => create a discount_object with those details

*now when someone finds this discount object => give link to create a cart directly with it,(there should be an action on cart_item called bulk_create => there will first create the cart items => then redirect_to create_cart => with those cart_items, and also the discount code)

*now in prepare_cart =>
if dicount_code is provided:

1.  check that the code id exsits
2.  check how many have been utilized
3.  if verification is necessary then send a message to the verifier, or in case the cart is being proxied, then the verification is bypassed => when he updates the discount object as verified(for that user id) 
4. if verification is not necessary , add the user to the discount object -> as those who used this.

*now if no verification is needed or after verification incorporate the discount_amount in the calculation of the cart_price.

*show the modified cart price.

*let him make a payment, he can make with amount as 0, with cash. gateway payment is disabled if pending balance is 0.

*the payment is instantly accepted if pending_balance is zero.

=end

module Auth::Concerns::Shopping::DiscountConcern

	extend ActiveSupport::Concern
		
	include Auth::Concerns::ChiefModelConcern
	include Auth::Concerns::OwnerConcern
	include Auth::Concerns::EsConcern


	included do 

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

		####################################################
		##
		## FIELDS
		##
		####################################################

		## the product ids that this discount object can contain.
		field :product_ids, type: Array, default: []
		
		## whether this discount object needs verification by the creator of the cart mentioned below, default is false
		field :requires_verification, type: Boolean, default: false

		## the total number of times this discount object can be used.
		field :count, type: Integer
		
		## the amount in plain float that this discount object provides
		field :discount_amount, type: Float, default: 0.0
		
		## the amount in percentage terms for discount, will be applied to the cart price.
		field :discount_percentage, type: Float, default: 0.0
		
		## the original cart on which this discount object was created from.
		field :cart_id, type: String

		## the cart is internally set.
		attr_accessor :cart
		
		field :verified, type: Array, default:[]

		field :pending, type: Array, default: []

		field :declined, type: Array, default: []
			
		## the hash of user ids who have used this discoutn code
		## key => [String] user id
		## value => [Integer] number of times used.
		field :used_by_users, type: Array, default: []


		## these attributes are used in the update action , to add the ids that should be marked as verified or declined.

		attr_accessor :add_verified_ids

		attr_accessor :add_declined_ids 
		
	#########################################################
	##
	## VALIDATIONS
	##
	#########################################################

		validate :cart_exists, :unless => :admin_and_cart_id_absent

		validate :one_discount_object_per_cart, if: Proc.new{|a| a.cart_id }

		validate :cart_has_multiples_of_all_items, if: Proc.new{|a| a.cart_id }

		validate :cart_can_create_discount_coupons, if: Proc.new { |a| a.cart_id }

		validate :user_can_create_discount_coupons

		validates :discount_percentage, numericality: { greater_than_or_equal_to: 0.0, less_than_or_equal_to: 100.0 }, if: Proc.new {|a| a.discount_percentage_changed?}

		validates :discount_amount, numericality: {greater_than_or_equal_to: 0.0}, if: Proc.new {|a| a.discount_amount_changed?}

		validate :discount_percentage_permitted, if: Proc.new {|a| a.discount_percentage_changed? && !a.admin_and_cart_id_absent}


		## SHOULD BE TESTED.
		## the maximum discount amount is not validated in case its an admin and the cart id is not provided
		validate :maximum_discount_amount, if: Proc.new {|a| (a.discount_amount_changed? || a.discount_percentage_changed?) && a.cart_id}

		## does not validate for product ids if the user is admin, and the cart is not present.
		validates :product_ids, presence: true, if: Proc.new{|a| a.cart_id}

		## validates for count irrespective.
		validates :count, presence: true

	#########################################################
	##
	##
	## CALLBACKS
	##
	##
	#########################################################

		before_validation do |document|

			document.set_cart
			
			if document.new_record?

				if document.cart
					## assign the products internally.
					document.product_ids = document.cart.cart_items.map{|citem| citem = citem.product_id}

					## assign count
					document.count = document.cart.cart_items.first.quantity
				else
					## whatever was sent in the params.
					## the count param is permitted only if the user is an admin.
				end				

			end

			## if either the discount amount or percentage is nil, set it to 0.

			document.discount_percentage = 0 if document.discount_percentage.nil?

			document.discount_amount = 0 if document.discount_amount.nil?

			## what is the maximum permissible amount?


			## give the add verified and declined ids, default values.

			document.add_verified_ids ||= []
			document.add_declined_ids ||= []


			document.pending = document.pending - ([document.add_declined_ids + document.add_verified_ids].flatten)

			document.verified = document.verified + document.add_verified_ids

			document.declined = document.declined + document.add_declined_ids

		end


		## all discounts are public to be searched.
		before_save do |document|
			self.public = "yes"
		end

		

	end

	module ClassMethods

		
		def find_discounts(options)
			conditions = {:resource_id => nil}
			conditions[:resource_id] = options[:resource].id.to_s if options[:resource]
			Auth.configuration.discount_class.constantize.where(conditions)
		end


		## @called_from : payment_concern.rb
		## @param[String] payment_id 
		## @return[BSON::Document] the document after the update or nil, in case nothing was updated.
		def add_pending_discount(payment_id,discount_object_id)
			Auth.configuration.discount_class.constantize.
			where({
				"$and" => [
					{
						"verified" => {
							"$ne" => payment_id
						}
					},
					{
						"pending" => {
							"$ne" => payment_id
						}
					},
					{
						"declined" => {
							"$ne" => payment_id
						}
					},
					{
						"_id" => BSON::ObjectId(discount_object_id)
					}
				]
			})
			.find_one_and_update(
				{
					"$push" => {
						:pending => payment_id
					}
				},
				{
					:return_document => :after	
				}
			)
		end

		## @called_from : payment_concern.rb
		## @param[String] payment_id : the id of the payment
		## @param[String] discount_object_id : the id of the discount object
		## @return[Integer] payment_status: returns the status that should be set for the payment.
		## @working: this def will match a discount object with the provided, id, and then filter the resulting fields to include any of the three arrays "pending","verified" or "declined" as long as they contain the payment id. It will return a payment_status that is to be set for the payment, based on teh result. If it finds that none of the arrays contain the payment id, then it will do a find and update to add the payment_id to the pending_array.

		def get_payment_status(payment,discount_object_id)



			results = Auth.configuration.discount_class.constantize.collection.aggregate([

				{
					"$match" => {
					"_id" => BSON::ObjectId(discount_object_id)
					}
				},
				{
					"$project" => {
						"verified" => {
							"$filter" => {
			                 	"input" => "$verified",
			                 	"as" => "verified",
			                 	"cond" => { 
			                 		"$eq" => 
			                 			[ "$$verified", payment.id.to_s 
			                 			] 
			                 	}
			            	}
						},
						"pending" => {
							"$filter" => {
			                 	"input" => "$pending",
			                 	"as" => "pending",
			                 	"cond" => { 
			                 		"$eq" => 
			                 			[ "$$pending", payment.id.to_s 
			                 			] 
			                 	}
			            	}
						},
						"declined" => {
							"$filter" => {
			                 	"input" => "$declined",
			                 	"as" => "declined",
			                 	"cond" => { 
			                 		"$eq" => 
			                 			[ "$$declined", payment.id.to_s 
			                 			] 
			                 	}
			            	}
						}
					}
				}

			])

			results_as_mongoid_docs = []

			results.each do |r|
				results_as_mongoid_docs << Mongoid::Factory.from_db(Auth.configuration.discount_class.constantize,r)
			end

			if results_as_mongoid_docs.empty?
				## this discont object does not exist
				## return 0
				#puts "------------------------there was no such discount object-----------------------------"
				0
			elsif !results_as_mongoid_docs[0].verified.empty?
				## it has been verified
				## so return 1
				puts "it has been verified"
				1
			elsif !results_as_mongoid_docs[0].declined.empty?
				## it has been declined
				## so return 0
				puts "it has been declined"
				0
			elsif !results_as_mongoid_docs[0].pending.empty?
				## it has not yet been acted on
				## so return nil
				puts "it is still pending."
				nil 
			else
				## it has to still be added
				## so in this case also the payment status will remain nil
				## but this has to indicate that it should be still added.
				## execute a find_and_update, where the payment id is not present in any of the three arrays, and then add it to the pending array.
				puts "came to add pending discount."
				doc_after = self.add_pending_discount(payment.id.to_s,discount_object_id)
				return 0 unless doc_after
				return nil
			end

		end


		## @called_from : payment_concern.rb
		## decrements the count by 1
		## if enforce_single_use is passed as false, a given user can utilize the discount any number of times.
		## checks that the count of the discount_object is greater than one before doing this.
		## returns the updated document after the update is complete.
		## if the document returned afterwards is nil, then it means that the payment_status will be set as failed.
		## otherwise, set the payment_status as 1. 
		def use_discount(discount,payment,enforce_single_use = true)

			## so we can check here if the cart has any items pending, before running this.
			## so we can only use the discount if all cart items are accepted
			if discount.cart_id
				discount.cart_can_create_discount_coupons
			end

			if discount.errors.full_messages.empty?
			
				query_hash = {
					:_id => discount.id.to_s,
					:pending => {"$ne" => payment.id.to_s},
					:declined => {"$ne" => payment.id.to_s},
					:count => {"$gte" => 1}
				}
				if enforce_single_use == true
					query_hash[:used_by_users => {"$ne" => payment.resource_id.to_s}]
				end
				updated_doc = Auth.configuration.discount_class.constantize.where(query_hash).find_one_and_update({
						"$inc" => {
							:count => -1
						},
						"$push" => {
							:used_by_users => payment.resource_id.to_s
						}
					},
					{
						:return_document => :after
					}
				)

				return 0 if updated_doc.nil?
				return 1

			else
				return 0
			end

		end

	end

	#######################################################
	##
	##
	## AUTOCOMPLETE METHODS.
	##
	##
	#######################################################
	def set_primary_link
		unless self.primary_link
			self.primary_link = Rails.application.routes.url_helpers.send(Auth::OmniAuth::Path.show_or_update_or_delete_path(Auth.configuration.discount_class),self.id.to_s)
		end
	end

	def set_autocomplete_tags
		self.tags = []
		self.tags << "Discount"
		self.tags << self.discount_amount.to_s if self.discount_amount
		self.tags << self.discount_percentage.to_s if self.discount_percentage
	end

	def set_autocomplete_description

	end

	def set_secondary_links
		
	end


	#######################################################
	##
	##
	## CALLBACK METHODS.
	##
	##
	#######################################################

	def set_cart
		begin
	
			if self.cart_id

				self.cart = Auth.configuration.cart_class.constantize.find(self.cart_id)
				
				
				self.cart.prepare_cart

			end

		rescue => e
			puts e.to_s
		end
	end

	#######################################################
	##
	##
	## VALIDATION METHODS.
	##
	##
	#######################################################

	def one_discount_object_per_cart
		discount_coupons_with_cart = 
		Auth.configuration.discount_class.constantize.where(:cart_id => self.cart_id.to_s)
		
		count = self.new_record? ? 0 : 1

		self.errors.add(:cart,"you can only create one discount coupon per cart") if discount_coupons_with_cart.size > count
		
	end


	def cart_exists
		self.errors.add(:cart,"the cart does not exist") unless self.cart
	end

	## this should only be if a cart id is provided.
	def cart_can_create_discount_coupons
		set_cart unless self.cart
		self.errors.add(:cart, "you cannot create discount coupons on this cart") unless cart.can_create_discount_coupons? 
	end


	def user_can_create_discount_coupons
		self.errors.add(:cart,"you cannot create discount coupons") unless get_resource.can_create_discount_coupons?
	end

	
	def cart_has_multiples_of_all_items
		self.errors.add(:cart,"the cart must have equal numbers of all items") if self.cart.cart_items.select{|c| c.quantity != self.count}.size > 0
	end


	def discount_percentage_permitted
		self.errors.add(:discount_percentage,"you cannot set a discount percentage") if self.discount_percentage > 0
	end


	def maximum_discount_amount
		## cannot exceed the sum of all cart items prices, we mean one multiple of the cart item prices.
		self.errors.add(:discount_amount,"the discount amount cannot exceed:") if self.discount_amount > (self.cart.cart_items.map{|c| c = c.price}.inject(:+))
	end



	## returns true if:
	## 1. the user is an admin
	## 2. there is no cart id.
	def admin_and_cart_id_absent
		#puts "signed in resource is:"
		#puts signed_in_resource.to_s
		#puts "is it an admin?"
		#puts signed_in_resource.is_admin?
		#puts "cart id is nil: #{cart_id.nil?}"
		signed_in_resource.is_admin? && cart_id.nil?
	end

end