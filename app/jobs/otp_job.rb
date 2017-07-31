class OtpJob < ActiveJob::Base
  include Auth::TwoFactorOtp
  include Auth::JobExceptionHandler

  queue_as :default
  self.queue_adapter = :sidekiq

  ##we currently log all exceptions to redis.
  rescue_from(StandardError) do |exception|
   	 
   	##if a resource id is defined in the arguments, then we log the error to that resources otp errors hash.
	if arguments[1].nil? || arguments[1]["_id"].nil? || arguments[1]["_id"]["$oid"].nil?
		TwoFactorOtp.log_error_to_redis(arguments[1]["_id"]["$oid"],exception.to_s)
	##otherwise we log the error using the job_exception_handler.
	else
		JobExceptionHandler.log_exception(exception)
	end
  	
  end
 
  ## expected array of arguments is: 
  ## 0 => resource class as string
  ## 1 => resource as json serialized, by calling JSON.generate()
  ## 2 => job_type : either "send_sms_otp" or "verify_sms_otp"
  ## 3 => hash of additional arguments if any
  def perform(*args)
	resource_class,resource_serialized,job_type,params = args[0],args[1],args[2],args[3]
	if resource_class && Auth.configuration.auth_resources[resource_class.singularize.capitalize]
		resource_class = resource_class.constantize
		resource_attrs = JSON.parse(resource_serialized)
		resource = resource_class.new(resource_attrs)
		if job_type == "send_sms_otp"
			resource.send_sms_otp
		elsif job_type == "verify_sms_otp"
			resource.verify_sms_otp
		end
	end
  end
end