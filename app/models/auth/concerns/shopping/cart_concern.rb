##NEED A SEPERATE MODEL THAT IMPLEMENTS IT
module Auth::Concerns::Shopping::CartConcern

	extend ActiveSupport::Concern
	
	include Auth::Concerns::ChiefModelConcern	

	included do 
		field :name, type: String
		field :notes, type: String
		field :resource_id, type: String
		
		## debit is calculated live, by first getting all the items already dispatched and their value, and then getting the total payments made and their value, so it infact becomes something at the validation level of the cart item.

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

	## gathers all the information about the cart
	## 
	def prepare_cart(resource)
		find_cart_items(resource)
		set_cart_price(resource)
		set_cart_payments(resource)
		set_cart_paid_amount(resource)
		set_cart_balance(resource)

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

	def has_balance
		self.cart_balance > 0
	end

	def fully_paid
		self.cart_balance = 0
	end

	def not_paid_at_all
		self.cart_balance == self.cart_price
	end


	## so imagine a situation
	## the item stage should be set for all items.
	def set_cart_item_stages
		if fully_paid
			## shift the stage of all cart_items to awaiting_confirmation
			## provided the stage is not already crossed that.
		elsif has_balance
			## shift the stage of all items which have an awaiting payment to awaiting confirmation.
			## the problem will be that we will again have to check before dispatch results, that there is 
			## some guy comes and says let the earlier tests be , i want these tests done first.
			## before setting stage to dispatch, it has to go on minusing that amount from the total paid , this is only necessary because we allow half payments.
		elsif not_paid_at_all
			## shift the stage of those cart items which have a payable at after the awaiting payment.
		else
		end
	end	

end
