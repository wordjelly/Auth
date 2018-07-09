class CommunicationJob < ActiveJob::Base
  queue_as :default
  self.queue_adapter = :delayed_job

  ##we currently log all exceptions to redis.
  rescue_from(StandardError) do |exception|
  	puts exception.message
   	puts exception.backtrace.join("\n")
  end
 
  def perform(arguments)
    if communication = Auth.configuration.communication_class.constantize.find_communication(arguments)
      if time = communication.deliver_all
        CommunicationJob.set(wait_until: time).perform_later(arguments)
      end
    end
  end

end