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
	
	included do 

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
			
		## the array of cart ids that have used this discount code(after verification if necessary)
		field :used_by_cart_ids, type: Array, default: []

		## the hash of user ids who have used this discoutn code
		## key => [String] user id
		## value => [Integer] number of times used.
		field :used_by_users, type: Hash, default: {}


	#########################################################
	##
	## VALIDATIONS
	##
	#########################################################


		validate :cart_exists

		validate :cart_fully_paid

		validate :cart_has_multiples_of_all_items

		validates :discount_percentage, numericality: { greater_than_or_equal_to: 0.0, less_than_or_equal_to: 100.0 }

		validates :discount_amount, numericality: {greater_than_or_equal_to: 0.0}

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
				## assign the cart ids internally.
				document.product_ids = document.cart.cart_items.map{|citem| citem = citem.product_id}

				## assign count
				document.count = document.cart.cart_items.first.quantity 

			end

			## if either the discount amount or percentage is nil, set it to 0.

			document.discount_percentage = 0 if document.discount_percentage.nil?

			document.discount_amount = 0 if document.discount_amount.nil?

		end


		module ClassMethods

			##used in cart_item_controller_concern#index
			## if there is a resource, will return all cart items with that resource id.
			## if there is no resource, will return all cart items with a nil rsource.
			def find_discounts(options)
				conditions = {:resource_id => nil}
				conditions[:resource_id] = options[:resource].id.to_s if options[:resource]
				Auth.configuration.cart_item_class.constantize.where(conditions)
			end

		end

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
			self.cart = @auth_shopping_cart_class.find(document.cart_id)
			self.cart.prepare_cart
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


	def cart_exists
		self.errors.add(:cart,"the cart does not exist") unless self.cart
	end


	def cart_can_create_discount_coupons
		self.errors.add(:cart, "you cannot create discount coupons on this cart") unless cart.can_create_discount_coupons? 
	end


	def user_can_create_discount_coupon
		self.errors.add(:cart,"you cannot create discount coupons") unless owner_resource.can_create_discount_coupons?
	end

	
	def cart_has_multiples_of_all_items
		self.errors.add(:cart,"the cart must have equal numbers of all items") if self.cart.cart_items.select{|c| c.quantity != self.count}
	end

	## so how does the discount finally work.
	## this has created a discount item.
	## now we need to be able to apply this concept
	## so the idea is that, at the time of calculating the cart total price.
	## so while creating the cart the discount 

end