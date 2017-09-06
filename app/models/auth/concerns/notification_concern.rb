module Auth::Concerns::NotificationConcern
		
	extend ActiveSupport::Concern
	include Auth::Concerns::ChiefModelConcern
	
	included do 

		include GlobalID::Identification

		## email subject.
		## the subject for email notifications.
		field :email_subject, type: String, default: "Notification from #{Auth.configuration.brand_name}"


		## short message : displayed in notification popup
		field :callout_message, type: String



		## a url that the user can visit to get more information about the notification.
		field :more_information_url, type: String



		## a collapse id, for gcm messages.
		field :collapse_id, type: String



		## to topics
		## the topics to which this notification is being sent.
		## this will only be applicable to gcm.
		field :topics, type: Array



		## resource class
		## the class of the resource to which this notification should be sent.
		field :resource_class, type: String



		## to resource_ids
		## array of resource_ids to which this notification is being sent.
		field :resource_ids, type: Array


		## a hash with query conditions determining to which resources this notification should be sent.
		field :resources_by_query, type: Hash


		## reply_to_email
		## an email address to which the user can reply in case of any issues
		field :reply_to_email, type: String



		## reply_to_number
		## a mobile phone number to which the user can reply in case of any issues.		
		field :reply_to_number, type: String

	end

	######################### FORMAT METHODS ####################

	def format_for_email(args)

	end

	def format_for_sms(args)

	end

	def format_for_android(args)

	end

	def format_for_ios(args)

	end

	def format_for_web(args)

	end

	######################### SEND METHODS ####################

	def send
		recipients = send_to
		recipients[:resources].map{|r|
			r.send_email
			r.send_sms
			r.send_mobile_notification
			r.send_desktop_notification	
		}
	end

	######################## UTILITY METHODS ##################

	## @return [Array] of resource objects.
	def get_resources
		resources = []
		resources << resource_ids.map{|c| resource_class_constantized.find(c)} if resource_ids
		resources << resource_class_constantized.where(resources_by_query) if resources_by_query
		resources
	end

	def get_topics
		topics || []
	end

	def send_to
		{:resources => get_resources, :topics => get_topics}
	end

	def resource_class_constantized
		resource_class.capitalize.constantize
	end

end