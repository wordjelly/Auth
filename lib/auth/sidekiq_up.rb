require "sidekiq/api"
module Auth
	module SidekiqUp
		## @param job_description[String]: a json representation of whatever job / arguments you wanted to pass into sidekiq, it is used to log an error in case sidekiq is down.
		## the determination of sidekiq begin down is done by checking if the queues hash is empty.
		## @return : yields the block called with this method in case the queues are not empty, otherwise the result of calling Rails.logger.error
		def self.sidekiq_running(job_description)
			stats = Sidekiq::Stats.new
			yield
			#yield unless stats.queues.empty?
			#Rails.logger.error("sidekiq could not do job because sidekiq was not started: #{job_description}") if stats.queues.empty?
		end
	end
end