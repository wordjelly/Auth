module Auth
	module Mailgun
		## returns the email after adding a webhook identifier variable.
		def add_webhook_identifier_to_email(email)
			email.message.mailgun_variables = {}
        	email.message.mailgun_variables["webhook_identifier"] = BSON::ObjectId.new.to_s
        	email
		end

		def self.set_webhook_identifier(notification_response,last_response)
			
			puts "last response is:"
			puts last_response


			last_response = JSON.parse(last_response).deep_symbolize_keys
			notification_response.webhook_identifier = last_response[:webhook_identifier] if not last_response[:webhook_identifier].nil?
		end


		def email_webhook(params)	
			
			Auth.configuration.notification_response_class.constantize.find_and_update_notification_response(params[:webhook_identifier], JSON.generate(params)) do |notification_response|

				#puts "found email notification response:"
				#puts notification_response.attributes.to_s

			end
		end
	end
end

