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

module Auth::Concerns::Shopping::PaymentConcern

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
		field :verification, type: Boolean, default: false

		## the total number of times this discount object can be used.
		field :count, type: Integer
		
		## the amount in plain float that this discount object provides
		field :discount_amount, type: Float, default: 0.0
		
		## the amount in percentage terms for discount, will be applied to the cart price.
		field :discount_percentage, type: Float, default: 0.0
		
		## the original cart on which this discount object was created from.
		field :origin_cart_id, type: String
		
		## the array of cart_ids, which have requested a verification for this discount code.
		field :pending_verification, type: Array, default: []
			
		## the array of cart ids that have used this discount code(after verification if necessary)
		field :used_by, type: Array, default: []

		## the hash of user ids who have used this discoutn code
		## key => [String] user id
		## value => [Integer] number of times used.
		field :used_by_users, type: Hash, default: {}


		#####################################################
		##
		## VALIDATIONS
		##
		#####################################################

		



	end

end