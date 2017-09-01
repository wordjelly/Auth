##NEED A SEPERATE MODEL THAT IMPLEMENTS IT
module Auth::Concerns::Shopping::CartConcern

	extend ActiveSupport::Concern
	
	include Auth::Concerns::ChiefModelConcern	

	included do 
		field :name, type: String
		field :notes, type: String
		field :resource_id, type: String
	end

	def find_cart_items(resource)
		conditions = {:resource_id => resource.id.to_s, :parent_id => self.id.to_s}
		Auth.configuration.cart_item_class.constantize.where(conditions)
	end

	## => 
	def total_cart_value(resource)

		total_value_of_all_items_in_cart = find_cart_items(resource).map{|c| c = c.price}.sum
	
	## => returns an array of payments made to the cart , alongwith verification errors if any.
	def all_payments(resource)
		payments_made_to_this_cart = Auth.configuration.payment_class.constantize.find_payments(resource,self)
		payments_made_to_this_cart.each do |payment|
			payment.verify_payment if payment.payment_pending
		end
		payments_made_to_this_cart		 
	end


end
