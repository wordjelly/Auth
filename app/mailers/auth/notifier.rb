class Auth::Notifier < ::ApplicationMailer
	default from: "from@example.com"
	## make sure that anything going into this argument implements includes globalid, otherwise serialization and deserialization does not work.
	def notification(resource,notification)
		@resource = resource
		@notification = Auth.configuration.notification_class.constantize.new
		mail to: "bhargav.r.raut@gmail.com", subject:  "#{Time.now}Now with new otp job architecture.  #{Auth.configuration.brand_name}"
	end
end
