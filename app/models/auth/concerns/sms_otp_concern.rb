module Auth::Concerns::SmsOtpConcern

	extend ActiveSupport::Concern

	included do 

		field :otp, type: Integer
		#attr_accessor :skip_send_sms_otp_callback
		#after_save :deconfirm_additional_param, if: :param_changed_and_dont_skip
		after_save :send_sms_otp, if: :param_changed_and_not_blank
	end

	##ALL THESE METHODS ARE OVERRIDEN IN THE MODEL THAT IMPLEMENTS
	##THIS CONCERN
	##THE MODEL SHOULD CALL THE METHODS OF THE RESPECTIVE ADAPTER
	##THAT IS USED FOR OTP.
	##INSIDE OF THESE METHOD.
	##E.G
	##USER MODEL
		## def send_sms_otp
			## adapter.send_sms_otp
			## super
		## end
	##END


	def check_otp_errors
		
	end


	
	def send_sms_otp
		##the user model will call the initial step of actually sending the sms otp.
		
		##we do this step because it is possible that send_sms_otp
	    ##can be called from a resend_otp requirement, in which case
	    ##the additional_login_param_status will already be 1, and we
	    ##wont need to save it.
	    #if self.additional_login_param_status_changed?
	    #  self.skip_send_sms_otp_callback = true
	    #  self.save 
	    #end
	    
	end
	
=begin
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
=end		
	##overridden in the model that implements this concern,
	##whoever calls this method , must set the self.additional_login_param_pre_request_status to 2, at the end of successfull verification,since this is needed for password recovery, unlocks mechanisms.
	def verify_sms_otp
		
	end

	private 

	##only do the callbacks if
	##1.the param has changed
	##AND NOT DONE ANYMORE THIS FOLLOWING CONDITION
	##2.we dont want to explicitly skip the callback.(this prevents recursive loops)
	##AND THIS IS DONE
	##3.the new param is not blank.(we dont want to send sms otp verification to a non-existent number)
	def param_changed_and_not_blank
		additional_login_param_changed? && !additional_login_param.blank?
	end


end

