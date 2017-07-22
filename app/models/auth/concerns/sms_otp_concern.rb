module Auth::Concerns::SmsOtpConcern

	extend ActiveSupport::Concern

	included do 

		after_save :send_sms_otp, if: :additional_login_param_changed?
		
	
		def send_sms_otp
				
		end

		def verify_sms_otp
			
		end


	end


end

