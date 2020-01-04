class NotiResponse
	include Auth::Concerns::NotificationResponseConcern
	
	def set_webhook_identifier(response)
		Auth::Mailgun.set_webhook_identifier(self,response)
		Auth::TwoFactorOtp.set_webhook_identifier(self,response)
	end

end