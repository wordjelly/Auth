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

	def total(resource)

		total_value_of_all_items_in_cart = find_cart_items(resource).map{|c| c = c.price}.sum
		
		##find payments made to this cart
		payments_made_to_this_cart = Auth.configuration.payment_class.constantize.find_payments(resource,self)
		total_payments = payments_made_to_this_cart.map{|c| c = c.amount}.sum

		##what about refunds made to this cart.
		##we will have to minus refunds as well.
		return total_value_of_all_items_in_cart - total_payments

	end

end
