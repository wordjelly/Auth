require "rails_helper"
RSpec.describe "sidekiq job spec",:email_notification => true, :type => :request do 

	it " -- logs error if sidekiq does not enqueue -- " do 

	end


	it " -- logs error if sidekiq rejects job -- " do 

	end


	it " -- logs error inside sidekiq job -- " do 

	end


	it " -- retries job if error in sidekiq job -- " do 

	end


	it " -- retries job if sidekiq restarts -- " do 

	end

end