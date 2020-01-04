class User < Auth::User
  include Mongoid::Document
  include Auth::Concerns::UserConcern
  include Auth::Concerns::SmsOtpConcern
  

  field :name, type: String

  create_es_index(INDEX_DEFINITION)
  
  ##FUNCTION OVERRIDEN FROM THE USER CONCERN TO FORMAT AND PARSE THE ADDITIONAL_LOGIN_PARAM.
  ##here we are processing it assuming it is a mobile number
  ##the regex is the same one used on the javascript side as well.
  def additional_login_param_format
   
  	if !additional_login_param.blank?
      
  		if additional_login_param =~/^([0]\+[0-9]{1,5})?([7-9][0-9]{9})$/
  			
      else
        
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

  def verify_sms_otp(otp)

      super(otp)
      ## will need to pass the request_send_password_link here. as well.
      OtpJob.perform_later([self.class.name.to_s,self.id.to_s,"verify_sms_otp",JSON.generate({:otp => otp})])
      
  end

  def check_otp_errors
      ## should make a call to the two factor otp check_errors class method, passing in self.
      Auth::TwoFactorOtp.resource = self
      Auth::TwoFactorOtp.check_errors
  end

=begin
  def send_reset_password_instructions
    token = set_reset_password_token
    send_reset_password_instructions_notification(token)
    puts "token is: #{token}"
    token
  end
=end
  ## only will work as long as you specify a default queue adapter at the application level, otherwise defaults to inline which basically means that it will block till email is sent.
  ## refer: https://github.com/mperham/sidekiq/wiki/Active-Job#active-job-setup
  def send_devise_notification(notification, *args)
    puts "sending devise notification."
    devise_mailer.send(notification, self, *args).deliver_later
    puts "finished send."
  end
  
  def send_reset_password_link
    super.tap do |r|
      if r
          notification = Noti.new
          resource_ids = {}
          resource_ids[User.name] = [self.resource_id]
          notification.resource_ids = JSON.generate(resource_ids)
          notification.objects[:payment_id] = r
          notification.save
          ## so this notification goes through here.
          ## 
          Auth::Notify.send_notification(notification)
      else
        #puts "no r."
      end
    end
  end


  def set_autocomplete_tags
      if self.new_record?
         self.tags << "user"
         self.tags << self.name
         self.tags << self.email
         self.tags << self.additional_login_param
      end
   end

end
