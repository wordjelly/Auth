module Auth::Concerns::SmsOtpConcern

	extend ActiveSupport::Concern

	included do 

		after_save :send_sms_otp, if: :additional_login_param_changed?

	
		def send_sms_otp
			puts "triggered send sms otp"
			response = Typhoeus.get("https://2factor.in/API/V1/#{TWO_FACTOR_SMS_API_KEY}/SMS/+91#{self.additional_login_param}/AUTOGEN")
			response_body = JSON.parse(response.body)
			if response_body[:Status] == "Success"
				##store in redis.
				##inside the delayed job.
				session[:otp_session_id] = response_body[:Details]
			end
		end

		def verify_sms_otp
			##push into delayed job
			##send user to page which polls every 3 seconds
			##if the confirmation has taken place, then just say
			##you have successfully verified your account.
			##sign in to continue.
			
		end

		def confirm_additional_login_param

			self.additional_login_param_confirmed = 1
		
		end

	end


end

##architecture
##need to have a place where the user can enter his otp and get it 
##verified
##so will need a controller for that
##confirmations controller can be extended to do that
##with additional actions for otp
##the actions would be new_otp
##create which would then 