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
   	##if a resource id is defined in the arguments, then we log the error to that resources otp errors hash.
	#if arguments[1].nil? || arguments[1]["_id"].nil? || arguments[1]["_id"]["$oid"].nil?
	#	Auth::TwoFactorOtp.log_error_to_redis(arguments[1]["_id"]["$oid"],exception.to_s)
	##otherwise we log the error using the job_exception_handler.
	#else
	#	Auth::JobExceptionHandler.log_exception(exception)
	#end
  	
  end
 
  ## expected array of arguments is: 
  ## 0 => resource class as string
  ## 1 => resource as json serialized, by calling JSON.generate()
  ## 2 => job_type : either "send_sms_otp" or "verify_sms_otp"
  ## 3 => hash of additional arguments if any
  def perform(args)
  	puts args.to_s
  	puts "here are the new args."
  	resource_class = args[0]
  	resource_attrs = JSON.parse(args[1])
  	job_type = args[2]

	if resource_class && Auth.configuration.auth_resources[resource_class]
		puts "conditions satisified."
		resource_class = resource_class.constantize
		resource = resource_class.new(resource_attrs)
		puts "resource is:"
		puts resource.to_s
		if job_type == "send_sms_otp"
			puts "came to send sms otp."
			resource.auth_gen(resource.id,resource.additional_login_param)
		elsif job_type == "verify_sms_otp"
			puts "came to verify sms otp"
			resource.verify_sms_otp
		end
	end

  end
end