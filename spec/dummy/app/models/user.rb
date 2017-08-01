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
    puts  "--------------- CAME TO VALIDATE ADDITIONAL LOGIN PARAM FORMAT----"
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
      super
      OtpJob.perform_later([self.class.name.to_s,self.id.to_s,"send_sms_otp"])
      
  end

  def verify_sms_otp

      super
      OtpJob.perform_later([self.class.name.to_s,self.id.to_s,"verify_sms_otp"])
      
  end

  def check_otp_errors
      ##so suppose it returns errors then what?
      check_errors
  end
  ##############
  ##
  ##
  ## END OVERRIDE.
  ##
  ###############

end
