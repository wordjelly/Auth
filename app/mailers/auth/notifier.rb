class Auth::Notifier < ApplicationMailer
	default from: "from@example.com"
	## make sure that anything going into this argument implements includes globalid, otherwise serialization and deserialization does not work.
	def notification(resource,notification)
		@resource = resource
		@notification = @notification
		## subject should be notification.subject.
		## to : @resource.email.
		mail to: "bhargav.r.raut@gmail.com", subject: "timepass"
	end
end
