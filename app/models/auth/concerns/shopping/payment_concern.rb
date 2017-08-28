##NEED A SEPERATE MODEL THAT IMPLEMENTS IT
module Auth::Concerns::Shopping::PaymentConcern

	extend ActiveSupport::Concern
	
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

		##the firstname of the payee
		field :firstname, type:String

		##the email of the payee
		field :email, type: String

		##the phone number of the payee
		field :phone, type: String

		##the url to redirect to on making a successfull payment
		field :surl, type: String

		##the url to redirect to when the payment fails.
		field :furl, type: String

	end


	def get_cart_name
		Auth.configuration.cart_class.constantize.find(cart_id).name
	end
	

end
