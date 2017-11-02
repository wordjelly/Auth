##NEED A SEPERATE MODEL THAT IMPLEMENTS IT
module Auth::Concerns::Shopping::CartConcern

	extend ActiveSupport::Concern
	
	include Auth::Concerns::ChiefModelConcern	
	include Auth::Concerns::OwnerConcern

	included do 
		field :name, type: String
		field :notes, type: String
		field :resource_id, type: String
		
		## debit is calculated live, by first getting all the items already dispatched and their value, and then getting the total payments made and their value, so it infact becomes something at the validation level of the cart item.

		## the total price of all the items in the cart
		attr_accessor :cart_price

		## the array of payment objects made upto now to this cart
		attr_accessor :cart_payments

		## the array of cart items in this cart.
		attr_accessor :cart_items

		## the amount the customer owes to us.
		attr_accessor :cart_pending_balance

		## the cumulative amount paid into this cart(sum of all successfull payments.)
		attr_accessor :cart_paid_amount

		## the credit the customer has pending in the cart.
		## this is used for sequentially debiting money from the cart_paid amount.
		attr_accessor :cart_credit

	end

	## sets all the attribute accessors of the cart.
	def prepare_cart(resource)
		find_cart_items(resource)
		set_cart_price(resource)
		set_cart_payments(resource)
		set_cart_paid_amount(resource)
		set_cart_pending_balance(resource)
		set_cart_credit(resource)
	end

	################ ATTR ACCESSOR SETTERS & GETTERS ##############

	## set the cart items, [Array] of cart items.
	def find_cart_items(resource)
		conditions = {:resource_id => resource.id.to_s, :parent_id => self.id.to_s}
		self.cart_items = Auth.configuration.cart_item_class.constantize.where(conditions)
		self.cart_items
	end

	def get_cart_items(resource)
		self.cart_items || find_cart_items(resource)
	end

	## => 
	def set_cart_price(resource)
		self.cart_price = total_value_of_all_items_in_cart = find_cart_items(resource).map{|c| c = c.price}.sum
		self.cart_price
	end

	def get_cart_price(resource)
		self.cart_price || set_cart_price(resource)
	end

	
	def set_cart_payments(resource)
		payments_made_to_this_cart = Auth.configuration.payment_class.constantize.find_payments(resource,self)
		payments_made_to_this_cart.each do |payment|
			payment.verify_payment if payment.payment_pending
		end
		self.cart_payments = payments_made_to_this_cart	
		self.cart_payments	 
	end

	def get_cart_payments(resource)
		self.cart_payments || set_cart_payments(resource)
	end

	def set_cart_paid_amount(resource)
		total_paid = 0
		payments = get_cart_payments(resource)
		price = get_cart_price(resource)
		payments.each do |payment|
			total_paid += payment.amount if (payment.payment_success)
		end
		self.cart_paid_amount = total_paid
		self.cart_paid_amount
	end

	def get_cart_paid_amount(resource)
		self.cart_paid_amount || set_cart_paid_amount(balance)
	end

	## how much money the customer still owes us.
	def set_cart_pending_balance(resource)
		self.cart_pending_balance = get_cart_price(resource) - get_cart_paid_amount(resource)
		self.cart_pending_balance
	end

	def get_cart_pending_balance(resource)
		self.cart_pending_balance || set_cart_pending_balance(resource)
	end


	## returns the credit set, or the the total amount paid by the customer.
	def set_cart_credit(resource,credit)
		credit || get_cart_paid_amount(resource)
	end

	## returns the credit if it exists, or the total amount paid by the customer, by calling set_cart_credit(resource)
	def get_cart_credit(resource)
		self.credit || set_cart_credit(resource)
	end

	## debits the cart_item price from the cart credit.
	## returns the current credit.
	def debit(amount,resource)
		set_cart_credit(resource,get_cart_credit(resource) - amount)
	end

	############# PAYMENT BALANCE CONVENIENCE METHODS #############

	## not fully paid, there is some amount to be taken from the customer yet.
	def has_pending(resource)
		get_cart_pending_balance(resource) > 0
	end

	## fully paid.
	def fully_paid(resource)
		get_cart_pending_balance(resource) == 0
	end

	## not paid a penny.
	def not_paid_at_all(resource)
		get_cart_pending_balance(resource) == get_cart_price(resource)
	end
end
