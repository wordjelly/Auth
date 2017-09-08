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
		## hash of resource_ids to which this notification is being sent.
		## key -> class_name 
		## value -> array of resource ids.
		## JSON encoded string.
		field :resource_ids, type: String, default: JSON.generate({})


		## a hash with query conditions determining to which resources this notification should be sent.
		## key -> class name
		## value -> query hash
		## JSON encoded string.
		field :resources_by_query, type: String, default: JSON.generate({})


		## reply_to_email
		## an email address to which the user can reply in case of any issues
		field :reply_to_email, type: String


		## reply_to_number
		## a mobile phone number to which the user can reply in case of any issues.		
		field :reply_to_number, type: String

		## objects related to this notification.
		## a hash of object ids, that refer to any objects that this notification deals with.
		## key -> string[preferably the class name, but can be anything if more than two objects of the same class are used.]
		## value -> bson::objectid of the instance of that class
		## these can be used to refer to , or pull up objects , pertaining to this notification.
		## eg, suppose you are sending a notification regarding an order object, then this would be a good place to store a key->value like: object_id: object.id.to_s
		## this can later be used when sending the notification, in the email/sms etc.
		field :objects, type: Hash, default: {}

		
		##################### RETRY COUNTS ######################

		field :sms_send_count, type: Integer, default: 0
		field :email_send_count, type: Integer, default: 0

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

	################ default max retry count ################### 

	def max_retry_count
		2
	end

	######################### SEND METHODS ####################


	## if the notification should be sent by email or not.
	## override in the implementing model.
	## default is true
	def send_by_email?(resource)
		true
	end


	## if the notification should be sent by sms or not.
	## override in the implementing model.
	## default is true
	def send_by_sms?(resource)
		resource.has_phone && resource.additional_login_param_confirmed?
	end

	## if the notification should be sent by mobile or not.
	## override in the implementing model.
	## default is true
	def send_by_mobile?(resource)
		true
	end


	## if the notification should be sent by desktop or not.
	## override in the implementing model.
	## default is true
	def send_by_desktop?(resource)
		true
	end

	## the user must implement a method called send_transactional_sms
	## this is defined in the sms_otp_concern.
	## remember to include this concern in the user, if using mobile numbers, and notification concern.
	def send_notification
		recipients = send_to
		recipients[:resources].map{|r|
			r.send_email(self) if send_by_email?(r)
			send_sms_background(r) if send_by_sms?(r)
			r.send_mobile_notification(self) if send_by_mobile?(r)
			r.send_desktop_notification(self) if send_by_desktop?(r)
		}
	end

	## defaults to just sending the sms direclty.
	## override using a background job to actually call the send_sms method.
	def send_sms_background(resource)
		send_sms(resource)
	end

	## creates a notification response object using the 
	def send_sms(resource)
		if self.sms_send_count < max_retry_count
			self.sms_send_count+=1
			create_notification_response(yield,"sms")
			self.save
		end
	end

	## @response[String] : a response received after sending a notification.
	## webhook identifier is called before_create by a callback. 
	def create_notification_response(response,type)
		notification_response = Auth.configuration.notification_response_class.constantize.new(notification_type: type, parent_notification_id: self.id.to_s)
		notification_response.add_response(response)
		notification_response.set_webhook_identifier
		notification_response.save
	end

	######################## UTILITY METHODS ##################

	## @return [Array] of resource objects.
	def get_resources
		resources = []

		JSON.parse(resource_ids).each do |class_name,ids|
			resources << ids.map{|c|
				class_name.capitalize.constantize.find(c)
			}
		end
		JSON.parse(resources_by_query).each do |class_name,query|
			resources << class_name.capitalize.constantize.where(query)
		end
		resources.flatten
	end

	def get_topics
		topics || []
	end

	def send_to
		{:resources => get_resources, :topics => get_topics}
	end

	def resource_class_constantized
		self.class.name.capitalize.constantize
	end

end