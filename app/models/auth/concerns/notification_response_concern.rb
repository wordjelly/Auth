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
	def add_response(json_response)
		self.responses << json_response
		yield if block_given?
	end

	## returns the parent notificatino object of this notification response.
	def get_parent_notification
		Auth.configuration.notification_class.constantize.find(self.parent_notification_id)
	end


	
	## fixes the identifier by which this response can be identified during webhook calls.
	def set_webhook_identifier
		puts "calling concern method."
	end


end