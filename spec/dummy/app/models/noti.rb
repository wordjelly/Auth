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
		puts "format for sms is:"
		puts response.to_s
		response
	end

	def send_sms_background(resource)
		OtpJob.perform_later([resource.class.name.to_s,resource.id.to_s,"send_transactional_sms",JSON.generate({:notification_id => self.id.to_s, :notification_class => self.class.name.to_s})])
	end


	def send_email_background(resource)
		## returns the mailgun variables hash as the notification response, and then sends the message.
		## there is no way to know if the deliver_later method fails, for example if the sidekiq is down or something like that.
		## we can only wait for the webhook to trigger.
		email = Auth.configuration.mailer_class.constantize.notification(resource,self)
		send_email(resource) do 
			email_message = email.message
			email_message.mailgun_variables = {}
			email_message.mailgun_variables["webhook_identifier"] = BSON::ObjectId.new.to_s
			## returns the mailgun variables hash as a json string to be added into the notification response. 
			JSON.generate(email_message.mailgun_variables)
		end
		email.deliver_later
	end
	

end