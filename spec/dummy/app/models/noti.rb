class Noti
	include Auth::Concerns::NotificationConcern
	def format_for_sms(resource)
		## in our case we are using two factor so it needs some parameters to be sent in.
		## it expects:
		## to_number,template_name,var_hash,template_sender_id
		## so here we return an array of arguments.
		response = {}
		response[:to_number] = resource.additional_login_param

		## the following three are things which will be specific to the template configured in twofactor.
		response[:template_name] = "test2"
		response[:var_hash] = {var1: resource.id.to_s, var2: objects[:payment_id]}
		response[:template_sender_id] = "PATHOF"
		
		response
	end

	def send_sms_background(resource)
		
		job_arguments = [resource.class.name.to_s,resource.id.to_s,"send_transactional_sms",JSON.generate({:notification_id => self.id.to_s, :notification_class => self.class.name.to_s})]
		#Auth::SidekiqUp.sidekiq_running(JSON.generate(job_arguments)) do 
		k = OtpJob.perform_later(job_arguments)
			puts "send sms background : perform_later returns: #{k.to_s}"
		#end
	end


	def send_email_background(resource)
		job_arguments = [resource.class.name.to_s,resource.id.to_s,"send_email",JSON.generate({:notification_id => self.id.to_s, :notification_class => self.class.name.to_s})]
		#Auth::SidekiqUp.sidekiq_running(JSON.generate(job_arguments)) do 
		k = OtpJob.perform_later(job_arguments)
		puts "send email background : perform_later returns: #{k.to_s}"
		#end
	end
	

	########################### TEST METHODS ####################
	def self.dummy
		n = Noti.new
		resource_ids = {}
		resource_ids[User.name] = ["59a5405c421aa90f732c9059"]
		n.resource_ids = JSON.generate(resource_ids)
		n.save
		n
	end

end