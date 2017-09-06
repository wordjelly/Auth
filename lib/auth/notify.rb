module Notify
	## first step is to determine the notification end points.
	## for eg: email/phone, android / iphone.
	## the args should be a hash.
	## it should have a resource or topic
	## it should have a notification object.
	## the method will determine which outputs are available for a particular resource.
	## and then call notification on each of those classes.
	def self.send_notification(notification)
		notification.send
	end
end
