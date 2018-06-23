class NotificationJob < ActiveJob::Base

  queue_as :default
  self.queue_adapter = :delayed_job

  ##we currently log all exceptions to redis.
  rescue_from(StandardError) do |exception|
  	puts exception.message
   	puts exception.backtrace.join("\n")
  end
 
  def perform(cart_item,instruction_index,notification_index)
    notification = cart_item.instructions[instruction_index].notifications[notification_index]
    notification.deliver_all
  end

end