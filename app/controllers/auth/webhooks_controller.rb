class Auth::WebhooksController <  ApplicationController
	skip_before_filter :verify_authenticity_token
	
	def sms_webhook

	end

	def email_webhook

	end

	
end