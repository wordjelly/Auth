##NEED A SEPERATE MODEL THAT IMPLEMENTS IT
module Auth::Concerns::Shopping::CartConcern

	extend ActiveSupport::Concern
	
	include Auth::Concerns::ChiefModelConcern	

	included do 
		field :name, type: String
		field :notes, type: String
		field :resource_id, type: String
		attr_accessor :cart_price
		attr_accessor :cart_payments
		attr_accessor :cart_items
	end

	def find_cart_items(resource)
		conditions = {:resource_id => resource.id.to_s, :parent_id => self.id.to_s}
		self.cart_items = Auth.configuration.cart_item_class.constantize.where(conditions)
		self.cart_items
	end

	## => 
	def set_cart_price(resource)
		self.cart_price = total_value_of_all_items_in_cart = find_cart_items(resource).map{|c| c = c.price}.sum
	end
	## => returns an array of payments made to the cart , alongwith verification errors if any.
	def set_cart_payments(resource)
		payments_made_to_this_cart = Auth.configuration.payment_class.constantize.find_payments(resource,self)
		payments_made_to_this_cart.each do |payment|
			payment.verify_payment if payment.payment_pending
		end
		self.cart_payments = payments_made_to_this_cart		 
	end


end
