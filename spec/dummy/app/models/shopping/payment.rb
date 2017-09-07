require "auth/notify"
class Shopping::Payment
	include Auth::Concerns::Shopping::PaymentConcern
	include Auth::Concerns::Shopping::PayUMoneyConcern
	include Auth::Notify
	after_save do |document|
		notification = Noti.new
		notification.resource_ids = [document.resource_id]
		notification.objects[:payment_id] = document.id.to_s
		Auth::Notify.send_notification(notification)
	end

end