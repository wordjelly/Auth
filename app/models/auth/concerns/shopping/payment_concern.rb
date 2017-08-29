##NEED A SEPERATE MODEL THAT IMPLEMENTS IT
module Auth::Concerns::Shopping::PaymentConcern

	extend ActiveSupport::Concern
		
	include Auth::Concerns::ChiefModelConcern

	included do 

		##the amount for this payment
		field :amount, type: Float

		##gateway
		##card
		##cash
		##cheque
		field :payment_type, type: String

		##the id of the cart for which this payment was made
		field :cart_id, type: String

	end

	module ClassMethods
		def find_payments(resource,cart)
			self.where(:resource_id => resource.id.to_s, :cart_id => cart.id.to_s)
		end		
	end

	
	##used in pay_u_money_helper.rb
	def get_cart_name
		cart = Auth.configuration.cart_class.constantize.find(cart_id)
		cart.name || "shopping cart"
	end

	def is_gateway?
		payment_type && payment_type == "gateway"
	end
		
end
