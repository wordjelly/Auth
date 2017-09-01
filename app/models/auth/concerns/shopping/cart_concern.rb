##NEED A SEPERATE MODEL THAT IMPLEMENTS IT
module Auth::Concerns::Shopping::CartConcern

	extend ActiveSupport::Concern
	
	include Auth::Concerns::ChiefModelConcern	

	included do 
		field :name, type: String
		field :notes, type: String
		field :resource_id, type: String
		
		## the total price of all the items in the cart
		attr_accessor :cart_price

		## the array of payments made upto now to this cart
		attr_accessor :cart_payments

		## the array of cart items in this cart.
		attr_accessor :cart_items

		## the balance payment to be made to this cart.
		attr_accessor :cart_balance

		## the cumulative amount paid into this cart(sum of all successfull payments.)
		attr_accessor :cart_paid_amount

	end

	def find_cart_items(resource)
		conditions = {:resource_id => resource.id.to_s, :parent_id => self.id.to_s}
		self.cart_items = Auth.configuration.cart_item_class.constantize.where(conditions)
		self.cart_items
	end

	## => 
	def set_cart_price(resource)
		self.cart_price = total_value_of_all_items_in_cart = find_cart_items(resource).map{|c| c = c.price}.sum
		self.cart_price
	end
	## => returns an array of payments made to the cart , alongwith verification errors if any.
	def set_cart_payments(resource)
		payments_made_to_this_cart = Auth.configuration.payment_class.constantize.find_payments(resource,self)
		payments_made_to_this_cart.each do |payment|
			payment.verify_payment if payment.payment_pending
		end
		self.cart_payments = payments_made_to_this_cart	
		self.cart_payments	 
	end

	def set_cart_paid_amount(resource)
		total_paid = 0
		payments = self.cart_payments || set_cart_payments(resource)
		price = self.cart_price || set_cart_price(resource)
		payments.each do |payment|
			total_paid += payment.amount if (payment.payment_success)
		end
		self.cart_paid_amount = total_paid
		self.cart_paid_amount
	end

	
	def set_cart_balance(resource)
		self.cart_balance = self.cart_price - self.cart_paid_amount
		self.cart_balance
	end

end
