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


		##the id of the resource that is making the payment.


	end

	module ClassMethods
		def find_payments(resource,cart)
			self.where(:resource_id => resource.id.to_s, :cart_id => cart.id.to_s)
		end		
	end

	def get_cart_name
		Auth.configuration.cart_class.constantize.find(cart_id).name
	end

	##return[Hash] of user attributes needed by the payment gateway
	##currently returns email, firstname and phone number
	def user_info_for_payment_gateway(resource)
		##only keep non nil keys out of email, additional_login_param and name.
		attrs = resource.attributes
		puts attrs.class.name.to_s
		ret = attrs.slice(:email,:additional_login_param,:name).keep_if{|k,v| v}
		##set phone as the additional login param if additional login param is not nil and its name is mobile. 
		ret[:phone] = ret.delete :additional_login_param if (ret[:additional_login_param] && Auth.configuration.auth_resources[resource.resource_key_for_auth_configuration][:additional_login_param_name] == "mobile")
		ret
	end
	
end
