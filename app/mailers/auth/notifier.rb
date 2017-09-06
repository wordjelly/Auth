class Auth::Notifier < ::ApplicationMailer
	default from: "from@example.com"
	## make sure that anything going into this argument implements includes globalid, otherwise serialization and deserialization does not work.
	def notification(resource,notification)
		@resource = resource
		@notification = notification
		mail to: "bhargav.r.raut@gmail.com", subject: @notification.email_subject || "Notification from #{Auth.configuration.brand_name}"
	end
end
