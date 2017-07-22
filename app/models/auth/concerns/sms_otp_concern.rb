module Auth::Concerns::SmsOtpConcern

	extend ActiveSupport::Concern

	included do 

		after_save :send_sms_otp, if: :additional_login_param_changed?

	
		def send_sms_otp
			self.additional_login_param_confirmed = 0
			##now do whatever is the rest of the implementation.
		end

		def verify_sms_otp
			
		end


	end


end

