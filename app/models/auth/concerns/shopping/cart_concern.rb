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

		before_destroy do |document|
			document.prepare_cart
			if document.cart_items.keep_if{|c| c.accepted == true}.size > 0
				false
			elsif document.get_cart_payments.size > 0 
				false
			end
		end
		
	end

	## sets all the attribute accessors of the cart.
	## @param[Payment] : a payment object can be passed in.
	## this is used in case there is a new payment which is calling prepare_cart. in that case the new payment has to be also added to the cart_payments. this is alwasy the case when a new payment is made with a status directly set as accepted, i.e for eg a cashier makes a payment on behalf of the customer.
	def prepare_cart

		find_cart_items
		
		set_cart_price
		
		set_cart_payments
		
		set_cart_paid_amount
		
		set_cart_pending_balance

	end

	################ ATTR ACCESSOR SETTERS & GETTERS ##############

	## set the cart items, [Array] of cart items.
	def find_cart_items
		conditions = {:resource_id => get_resource.id.to_s, :parent_id => self.id.to_s}
		self.cart_items = Auth.configuration.cart_item_class.constantize.where(conditions).order(:created_at => 'desc')
		
		self.cart_items
	end

	def get_cart_items
		self.cart_items 
	end

	## => 
	def set_cart_price
		self.cart_price = total_value_of_all_items_in_cart = get_cart_items.map{|c| c = c.price}.sum
		self.cart_price
	end

	def get_cart_price
		self.cart_price 
	end

	
	def set_cart_payments
		self.cart_payments = []
		payments_made_to_this_cart = Auth.configuration.payment_class.constantize.find_payments(get_resource,self)
		
		payments_made_to_this_cart.each do |payment|
			payment.verify_payment if payment.payment_pending
			self.cart_payments << payment
		end
		
		


		self.cart_payments	 
	end

	def get_cart_payments
		self.cart_payments 
	end

	def set_cart_paid_amount
		total_paid = 0
		payments = get_cart_payments
		price = get_cart_price
		payments.each do |payment|

			total_paid += payment.amount if (payment.payment_success)
		end
		self.cart_paid_amount = total_paid
		
		self.cart_credit = self.cart_paid_amount
		self.cart_paid_amount
	end

	## sum total of all payments made to the cart.
	def get_cart_paid_amount
		self.cart_paid_amount 
	end

	## how much money the customer still owes us.
	def set_cart_pending_balance
		self.cart_pending_balance = get_cart_price - get_cart_paid_amount
	end

	def get_cart_pending_balance
		self.cart_pending_balance 
	end

	## initially is the same as cart_paid_amount, by calling debit, we can debit from credit, the costs of various items.
	def get_cart_credit
		self.cart_credit 
	end

	## debits the @amount from the cart credit.
	## returns the current credit.
	def debit(amount)
		#puts "want to debit: #{amount}"
		#puts "current credit is: #{self.cart_credit}"
		self.cart_credit-=amount
		
		#puts "after debiting: #{self.cart_credit}"
		self.cart_credit
	end

	############# PAYMENT BALANCE CONVENIENCE METHODS #############

	## not fully paid, there is some amount to be taken from the customer yet.
	def has_pending
		get_cart_pending_balance > 0
	end

	## fully paid.
	def fully_paid
		get_cart_pending_balance == 0
	end

	## not paid a penny.
	def not_paid_at_all
		get_cart_pending_balance == get_cart_price
	end



	## returns the amount that needs to be refunded to the customer from this cart.
	## @return : 0 if the pending_balance is greater than 0,otherwise returns the pending balance.
	def refund_amount
		return 0 unless get_cart_pending_balance < 0
		return get_cart_pending_balance
	end

	## just replaces the cart_items with an array of cart_item_ids
	## replaces the cart_payments with an array of cart_payment_ids
	## then returns a hash with these two instead of the original values.
	## @used_in : Shopping::PaymentConcern.set_receipt.
	def prepare_receipt
		cart_item_ids = cart_items.map{|c| c = c.id.to_s}
		cart_payment_ids = cart_payments.map{|c| c = c.id.to_s}
		receipt = self.attributes.merge({:cart_items => cart_item_ids, :cart_payments => cart_payment_ids})
		receipt
	end

	## checks if there are any items in the cart.
	## expected that prepare_cart has been called in advance.
	## return[Boolean] true if there is one or more items in the cart
	## @used_in: payment_concern validation cart_not_empty
	def has_items?
		get_cart_items.size > 0
	end


	##adds a validation error if the cart items could not be successfully added or removed.
	##called from the controller.
	##TODO: you should change this to be called before_validation instead, so that all code remains in the model.
	def add_or_remove(item_ids,add_or_remove)
	    add_remove_results = item_ids.map {|id|
	      if cart_item = Auth.configuration.cart_item_class.constantize.find(id)
	      	cart_item.signed_in_resource = self.signed_in_resource
	        resp = (add_or_remove == 1) ? cart_item.set_cart_and_resource(self) : cart_item.unset_cart
	        puts "the response of adding the cart item is:#{resp.to_s}" 
	        resp

	      else
	        true 
	      end
	    }.compact.uniq
	    self.errors.add(:cart_items,"some cart items could not be added or removed successfully") if ((add_remove_results.size > 1) || (add_remove_results[0] == false))  
	end

end
