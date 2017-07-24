class OtpJob < ActiveJob::Base
  queue_as :default
  self.queue_adapter = :sidekiq
  def perform(*args)
	resource_class = args[0]
	resource_serialized = args[1]
  end
end