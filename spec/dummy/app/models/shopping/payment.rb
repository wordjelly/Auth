require "auth/notify"
class Shopping::Payment < Auth::Shopping::Payment
	include Auth::Concerns::Shopping::PayUMoneyConcern
	include Auth::Notify
	after_save do |document|
		notification = Noti.new
		resource_ids = {}
		resource_ids[User.name] = [document.resource_id]
		notification.resource_ids = JSON.generate(resource_ids)
		notification.objects[:payment_id] = document.id.to_s
		notification.save
		Auth::Notify.send_notification(notification)
	end

end