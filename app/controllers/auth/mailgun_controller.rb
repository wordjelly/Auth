class Auth::MailgunController <  ApplicationController
 	skip_before_filter :verify_authenticity_token

 	def email_webhook

 	end

end
