module Auth::Concerns::NotificationResponseConcern
	extend ActiveSupport::Concern
	

	included do 
		include Auth::Concerns::ChiefModelConcern
		include Auth::Concerns::OwnerConcern
		include GlobalID::Identification
		field :notification_type, type: String
		validates_presence_of :notification_type
		## array of json responses.
		## example from the webhook, or the initial notification send response.
		field :responses, type: Array, default: []
		field :parent_notification_id, type: String
		validates_presence_of :parent_notification_id

		## field to search for during the webhook callback.
		## the webhook should search for where(:webhook_identifier => something provided by the webhook.)
		field :webhook_identifier
		validates_presence_of :webhook_identifier

		
	end

	## the idea here is the process the response by means of a block.
	## json response should be a string representation of a valid json object.
	def add_response(json_response)
		self.responses << json_response
		yield if block_given?
	end

	## returns the parent notificatino object of this notification response.
	def get_parent_notification
		Auth.configuration.notification_class.constantize.find(self.parent_notification_id)
	end


	
	## fixes the identifier by which this response can be identified during webhook calls.
	## @param response[String] : the json string that contains the response that was obtained by sending the notification.
	def set_webhook_identifier(response)
		
	end


	module ClassMethods

		## @param webhook_identifier[String] : an identifier by which to search for a notification response object
		## @param params[String] : a JSON string of whatever was received from the webhook request.
		## &block, optional block.
		## return the notification_response object, after adding the response to it and saving it, if it was found
		## yields the provided block after calling save.
		## check the notification_response to see if it was successfully saved.
		## return nil otherwise, and logs a rails error.
		def find_and_update_notification_response(webhook_identifier,params,&block)
			puts "webhook identifier is: #{webhook_identifier}"
			if notification_response = Auth.configuration.notification_response_class.constantize.where(:webhook_identifier => webhook_identifier)
		 		notification_response = notification_response.first
		 		notification_response.add_response(params)
		 		notification_response.save
		 		yield(notification_response) if block_given?
		 		notification_response
		 	else
		 		Rails.logger.error("webhook identifier not found: #{webhook_identifier}")
		 	end
		end

	end

end

