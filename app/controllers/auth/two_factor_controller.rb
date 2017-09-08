class Auth::TwoFactorController <  ApplicationController
 	skip_before_filter :verify_authenticity_token
 	def transactional_sms_webhook_endpoint
 		if notification_response = Auth.configuration.notification_response_class.constantize.where(:webhook_identifier => permitted_params[:SessionId])
 			
 			notification_response = notification_response.first

 			notification_response.add_response(permitted_params)

 			if transactional_sms_failed?
 				notification = notification_response.get_parent_notification
 				resource = notification_response.get_resource
 				notification.send_sms_background(resource)
 			end

 			notification_response.save
 		
 		else
 			Rails.logger.error("webhook hit for non existing session id: #{permitted_params[:SessionId]}" )
 		end
 	end


 	def transactional_sms_delivered?
 		permitted_params[:StatusGroupId] && permitted_params[:StatusGroupId].to_s == "3"
 	end

 	def transactional_sms_pending?
 		permitted_params[:StatusGroupId] && permitted_params[:StatusGroupId].to_s =~ /0|1/
 	end

 	def transactional_sms_failed?
 		!permitted_params[:StatusGroupId] || (permitted_params[:StatusGroupId] && permitted_params[:StatusGroupId].to_s =~ /2|4|5/)
 	end

 	def permitted_params
 		params.permit(:SessionId,:SmsTo,:SmsStatus,:StatusGroupId,:StatusGroupName,:StatusId,:StatusName,:StatusDescription)
 	end

end