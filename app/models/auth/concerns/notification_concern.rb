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

	## returns the name of a partial to be rendered.
	def email_partial
		"auth/notifier/email.html.erb"
	end

	def format_for_sms(resource)

	end

	def format_for_android(resource)

	end

	def format_for_ios(resource)

	end

	def format_for_web(resource)

	end

	######################### SEND METHODS ####################


	## if the notification should be sent by email or not.
	## override in the implementing model.
	## default is true
	def send_by_email?
		true
	end


	## if the notification should be sent by sms or not.
	## override in the implementing model.
	## default is true
	def send_by_sms?
		true
	end

	## if the notification should be sent by mobile or not.
	## override in the implementing model.
	## default is true
	def send_by_mobile?
		true
	end


	## if the notification should be sent by desktop or not.
	## override in the implementing model.
	## default is true
	def send_by_desktop?
		true
	end

	## the user must implement a method called send_transactional_sms
	## this is defined in the sms_otp_concern.
	## remember to include this concern in the user, if using mobile numbers, and notification concern.
	def send
		recipients = send_to
		recipients[:resources].map{|r|
			r.send_email(self) if send_by_email?
			r.send_notification_sms(self) if send_by_sms?
			r.send_mobile_notification(self) if send_by_mobile?
			r.send_desktop_notification(self) if send_by_desktop?
		}
	end

	######################## UTILITY METHODS ##################

	## @return [Array] of resource objects.
	def get_resources
		resources = []
		resources << resource_ids.map{|c| resource_class_constantized.find(c)} if resource_ids
		resources << resource_class_constantized.where(resources_by_query) if resources_by_query
		resources.flatten
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