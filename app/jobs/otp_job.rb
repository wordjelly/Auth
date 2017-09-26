require "/home/bhargav/Github/auth/lib/auth/two_factor_otp"
class OtpJob < ActiveJob::Base
  include Auth::TwoFactorOtp
  include Auth::JobExceptionHandler

  queue_as :default
  self.queue_adapter = :sidekiq

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
  	puts "came to perform in sidekiq job."
  	resource_class = args[0]
  	resource_id = args[1]
  	job_type = args[2]
    params = (args.size == 4) ? JSON.parse(args[3]).deep_symbolize_keys : nil 
    
	if resource_class && Auth.configuration.auth_resources[resource_class]
		resource_class = resource_class.constantize
		resource = resource_class.find(resource_id)
		
    ## the resource methods mentioned here are added throgh the TwoFactorOtp module.

		if job_type == "send_sms_otp"
			resource.auth_gen
		elsif job_type == "verify_sms_otp"
			resource.verify(params[:otp])
    elsif job_type == "send_transactional_sms"
      notification = params[:notification_class].capitalize.constantize.find(params[:notification_id])
      ## calling the block 
      notification.send_sms(resource) do 
        Auth::TwoFactorOtp.send_transactional_sms(notification.format_for_sms(resource))
      end
    elsif job_type == "send_email"
      notification = params[:notification_class].capitalize.constantize.find(params[:notification_id])
      email = Auth.configuration.mailer_class.constantize.notification(resource,self)
      email.message.mailgun_variables = {}
      email.message.mailgun_variables["webhook_identifier"] = BSON::ObjectId.new.to_s
      notification.send_email(resource) do 
        JSON.generate(email.message.mailgun_variables)      
      end
      email.deliver_now
		end
	end

  end
end