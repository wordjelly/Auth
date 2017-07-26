module Auth::Concerns::SmsOtpConcern

	extend ActiveSupport::Concern

	included do 

		
		attr_accessor :otp
		attr_accessor :skip_send_sms_otp_callback
		after_save :deconfirm_additional_param, if: :param_changed_and_dont_skip
		after_save :send_sms_otp, if: :param_changed_and_dont_skip
		


			
		

		def deconfirm_additional_param
			##this is assumed as pending because we dont know exactly when the remote job will send the sms
			##so we set this as pending.
			##a more fine granularity can be got by first making it unconfirmed and later sending a push notification that it is now pending.
			##as follows
			##self.additional_login_param_status = "unconfirmed"
			##so now it is directly pending.
			puts "deconfirming"
			self.additional_login_param_status = 1
		end
		
		##these are overriden in the MODEL that implements this concern. 
		def send_sms_otp
			
		end

		##overridden in the model that implements this concern,
		def verify_sms_otp
			
		end

		private 

		def param_changed_and_dont_skip
			additional_login_param_changed? && (skip_send_sms_otp_callback.nil?)
		end

	end

	


end

