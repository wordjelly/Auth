class User
  include Mongoid::Document
  include Auth::Concerns::UserConcern
  include Auth::Concerns::SmsOtpConcern
  include Auth::TwoFactorOtp

  field :name, type: String
  field :dog, type: String

  
  ##FUNCTION OVERRIDEN FROM THE USER CONCERN TO FORMAT AND PARSE THE ADDITIONAL_LOGIN_PARAM.
  ##here we are processing it assuming it is a mobile number
  ##the regex is the same one used on the javascript side as well.
  def additional_login_param_format
  	if !additional_login_param.blank?
  		if !additional_login_param =~/^([0]\+[0-9]{1,5})?([7-9][0-9]{9})$/
  			errors.add(:additional_login_param,"please enter a valid mobile number")
  		end
  	end
  end 

  ################
  ##
  ## OVERRIDE SMS OTP METHODS
  ## auth/app/models/auth/concerns/sms_otp_concern.rb
  ## 
  ################
  def send_sms_otp
    ##The super tap just sets the additional_param_confirmed
    ##to 0 i.e unconfirmed.
      auth_gen(self.id,self.additional_login_param)
      ##we do this step because it is possible that send_sms_otp
      ##can be called from a resend_otp requirement, in which case
      ##the additional_login_param_status will already be 1, and we
      ##wont need to save it.
      if self.additional_login_param_status_changed?
        self.skip_send_sms_otp_callback = true
        self.save 
      end
  end

  def verify_sms_otp(user_provided_otp)
      
      verify(self.class,self.id,user_provided_otp)
    
  end

  ##############
  ##
  ##
  ## END OVERRIDE.
  ##
  ###############

end
