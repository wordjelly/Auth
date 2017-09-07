module Auth::Notify
	def self.send_notification(notification)
		notification.send
	end
end
