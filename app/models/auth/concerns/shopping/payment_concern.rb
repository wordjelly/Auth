##NEED A SEPERATE MODEL THAT IMPLEMENTS IT
module Auth::Concerns::Shopping::PaymentConcern

	extend ActiveSupport::Concern
	
	included do 

		##the unique transaction id associated with each payment
		field :transaction_id, type: String, default: BSON::ObjectId.new.to_s

		## => gateway : 0
		## => card : 1
		## => cash : 2
		## => cheque : 3
		field :payment_type, type: Integer

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

	def payment_type_is
		return "gateway_payment" if payment_type == 0
		return "card_payment" if payment_type == 1
		return "cash_payment" if payment_type == 2
		return "cheque_payment" if payment_type == 3
	end


end
