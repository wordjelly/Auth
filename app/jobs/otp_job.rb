#require "/home/bhargav/Github/auth/lib/auth/two_factor_otp"
class OtpJob < ActiveJob::Base
  include Auth::TwoFactorOtp
  include Auth::Mailgun
  include Auth::JobExceptionHandler

  queue_as :default
  self.queue_adapter = :delayed_job

  ##we currently log all exceptions to redis.
  rescue_from(StandardError) do |exception|
  	puts exception.message
   	puts exception.backtrace.join("\n")
  end
 
  ## expected array of arguments is: 
  ## 0 => resource class as string
  ## 1 => resource as json serialized, by calling JSON.generate()
  ## 2 => job_type : either "send_sms_otp" or "verify_sms_otp"
  ## 3 => hash of additional arguments if any
  def perform(args)
  	
  	resource_class = args[0]
  	resource_id = args[1]
  	job_type = args[2]
    params = (args.size == 4) ? JSON.parse(args[3]).deep_symbolize_keys : nil 
    

    ############### WEBHOOK JOBS ##########################

    if job_type == "sms_webhook"

      sms_webhook(params)

    elsif job_type == "email_webhook"

      email_webhook(params)

    end

    ############### JOBS THAT NEED A RESOURCE #############

	  if resource_class && Auth.configuration.auth_resources[resource_class]
		
      resource_class = resource_class.constantize
		  

      resource = resource_class.find(resource_id)
		
      
      Auth::TwoFactorOtp.resource = resource
  		

      if job_type == "send_sms_otp"
  			

        auth_gen
  		

      elsif job_type == "verify_sms_otp"
  		

      	verify(params[:otp])
      

      elsif job_type == "send_transactional_sms"
        

        notification = params[:notification_class].capitalize.constantize.find(params[:notification_id])
        notification.send_sms(resource) do 
          send_transactional_sms(notification.format_for_sms(resource))
        end


      elsif job_type == "send_email"
      
        notification = params[:notification_class].capitalize.constantize.find(params[:notification_id])
        email = Auth.configuration.mailer_class.constantize.notification(resource,self)
        email = add_webhook_identifier_to_email(email)
      
        notification.send_email(resource) do 
          JSON.generate(email.message.mailgun_variables)      
        end
      
        email.deliver_now
  	
      end
      
	  end

  end
end