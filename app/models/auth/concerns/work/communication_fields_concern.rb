## this should be added to any class that embeds communication.rb
module Auth::Concerns::Work::CommunicationFieldsConcern

	extend ActiveSupport::Concern
	
	included do 	
				
		####################################################################
		##
		##
		## COMMON FIELDS
		##
		## defaults to the home page.
		##
		####################################################################
		field :link, type: String, default: Auth.configuration.host_name

		####################################################################
		##
		##
		## EMAIL RELATED FIELDS.
		##
		##
		####################################################################
		field :email_subject, type: String, default: "Attention : #{Auth.configuration.brand_name}"
		field :email_content, type: String, default: "Hi this email is from #{Auth.configuration.brand_name}"

		####################################################################
		##
		## 
		## SMS RELATED FIELDS.
		##
		##
		####################################################################
		field :sms_content, type: String, default: "Hi this message is from #{Auth.configuration.brand_name}"
		
		####################################################################
		##
		##
		## MOBILE NOTIFICATIONS.
		##
		##
		####################################################################
		field :notification_badge, type: String, default: "default"
		field :notification_content, type: String, default: "Hi this message is from #{Auth.configuration.brand_name}"

		########################################################################
		##
		##
		## It is expected that form fields will be added to the implementing object, for all the fields above. At the same time, the implementing object can override the methods below to provided customization for the fields. In the end, communication.rb, will call these methods on the parent object(eg instruction/cycle), and use the returned values, while sending the notifications.
		## so for instructions what would you like to have ?
		##
		##
		########################################################################
		
	end

	def get_link(args={})
		self.link
	end

	def get_email_subject(args={})
		self.email_subject
	end

	def get_email_content(args={})
		self.email_content
	end

	def get_sms_content(args={})
		self.sms_content
	end

	def get_notification_badge(args={})
		self.notification_badge
	end

	def get_notification_content(args={})
		self.notification_content
	end

end