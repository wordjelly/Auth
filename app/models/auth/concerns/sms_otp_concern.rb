module Auth::Concerns::SmsOtpConcern

	extend ActiveSupport::Concern

	included do 

		after_save :deconfirm_additional_param, if: :additional_login_param_changed?
		after_save :send_sms_otp, if: :additional_login_param_changed?
		attr_accessor :otp
		def deconfirm_additional_param
			##this is assumed as pending because we dont know exactly when the remote job will send the sms
			##so we set this as pending.
			##a more fine granularity can be got by first making it unconfirmed and later sending a push notification that it is now pending.
			##as follows
			##self.additional_login_param_status = "unconfirmed"
			self.additional_login_param_status = "pending"
		end
		
		##after send, 
		def send_sms_otp
			
		end

		def verify_sms_otp
			
		end

	end


end

