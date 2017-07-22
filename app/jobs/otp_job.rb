class OtpJob < ActiveJob::Base
  queue_as :default
  self.queue_adapter = :sidekiq
  def perform(*args)
	    puts "hello there how are you"
  end
end