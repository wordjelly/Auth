class Auth::Work::Information
	include Mongoid::Document
	field :resource_id, type: String
	field :send_at, type: Time
	field :payload_for_sms, type: String
	field :payload_for_email, type: String
	field :payload_for_mobile_notification, type: String

	## how to format the email / sms / mobile app notification

	field :email_format_option, type: String
	field :sms_format_option, type: String
	field :notification_format_option, type: String
	
	def inform
	end

	

end