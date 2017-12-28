module Auth::Notify
	def self.send_notification(notification)
		## for tests.
		##return if Auth.configuration.notify == false
		notification.send_notification
	end

end
