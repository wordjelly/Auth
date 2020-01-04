require "rails_helper"

RSpec.describe "unlock request spec", :type => :request,:authentication => true, unlock: true do 	

	before(:example) do 
		ActionController::Base.allow_forgery_protection = false
      	User.delete_all
      	Auth::Client.delete_all
      	@u = User.new(attributes_for(:user_confirmed))
      	@u.save
      	@u.lock_access!
      	@u.save
      	##HERE THE USER IS NOT CONFIRMED, SO THE CLIENT IS NOT CREATED IN THE AFTER_sAVE BLOCK.
      	##AS A RESULT WE MANUALLY CREATE A CLIENT.
      	##WE USE THIS SAME CLIENT FOR THE API_KEY AND REDIRECT_URL.
      	##NORMALLY THIS WOULD BE A CLIENT OF ANOTHER USER, ENTIRELY.
      	@c = Auth::Client.new(:resource_id => @u.id)
        @c.api_key = "test"
      	@c.redirect_urls = ["http://www.google.com"]
      	@c.app_ids << "test_app_id"
      	@c.versioned_create
      	@ap_key = @c.api_key	
      	@headers = { "CONTENT_TYPE" => "application/json" , "ACCEPT" => "application/json"}

    end

	after(:example) do 
		User.delete_all
      	Auth::Client.delete_all
	end

	context "--- web app requests--" do 

		before(:example) do 

			ActionController::Base.allow_forgery_protection = false

		end


		context "-- invalid api key -- " do 

			it " -- new -- " do 

				get new_user_unlock_path,{}
				expect(response.code).to eq("200")

			end

			it " -- create -- " do 

				prev_msg_count = ActionMailer::Base.deliveries.size
				post user_unlock_path,params: {user:{email: @u.email}}
				expect(response.code).to eq("302")
				message = ActionMailer::Base.deliveries[-1].to_s
    			token = nil
      			message.scan(/unlock_token=(?<unlock_token>.*)\"/) do |ll|

      				j = Regexp.last_match
      				token = j[:unlock_token]

      			end
    			new_msg_count = ActionMailer::Base.deliveries.size
    			expect(token).not_to be(nil)
    			expect(new_msg_count - prev_msg_count).to eq(1)
				@u.reload
						

			end	

			it " -- show -- ", problem: true do 

				@u.send_unlock_instructions
				@u.reload
				message = ActionMailer::Base.deliveries[-1].to_s
    			token = nil
      			message.scan(/unlock_token=(?<unlock_token>.*)\"/) do |ll|

      				j = Regexp.last_match
      				token = j[:unlock_token]

      			end
    			get user_unlock_path,params: {unlock_token: token}
    			expect(response.code).to eql("302")
    			@u.reload
    			expect(@u.access_locked?).not_to be_truthy
    			expect(@u.unlock_token).to be_nil
    			expect(@u.locked_at).to be_nil
    			
			end

		end

		context " -- valid api key + redirect_url -- " do 

			it " -- new should not redirect" do 
				get new_user_unlock_path, params: {redirect_url: "http://www.google.com", api_key: @ap_key, current_app_id: @c.app_ids[0]}
				expect(session[:client]).not_to be_nil
				expect(session[:redirect_url]).not_to be_nil
				expect(response.code).to eq("200")	
			end

			it " -- create should not redirect" do 
				prev_msg_count = ActionMailer::Base.deliveries.size
				post user_unlock_path, params: {user:{email: @u.email},redirect_url: "http://www.google.com", api_key: @ap_key, current_app_id: @c.app_ids[0]}
				expect(session[:client]).not_to be_nil
				expect(session[:redirect_url]).not_to be_nil
				expect(response.code).to eq("302")
				message = ActionMailer::Base.deliveries[-1].to_s
    			token = nil
      			message.scan(/unlock_token=(?<unlock_token>.*)\"/) do |ll|

      				j = Regexp.last_match
      				token = j[:unlock_token]

      			end
    			new_msg_count = ActionMailer::Base.deliveries.size
    			expect(token).not_to be(nil)
    			
    			expect(new_msg_count - prev_msg_count).to eq(1)
				expect(response.location=~/google/).to be_nil
			end

			it " -- show should not redirect" do 
				
				@u.send_unlock_instructions
				@u.reload
				message = ActionMailer::Base.deliveries[-1].to_s
    			token = nil
      			message.scan(/unlock_token=(?<unlock_token>.*)\"/) do |ll|

      				j = Regexp.last_match
      				token = j[:unlock_token]

      			end
    			get user_unlock_path,params: {unlock_token: token,redirect_url: "http://www.google.com", api_key: @ap_key, current_app_id: @c.app_ids[0]}

    			expect(session[:client]).not_to be_nil
				expect(session[:redirect_url]).not_to be_nil
    			expect(response.code).to eql("302")
    			db_user = User.where(:email => @u.email).first
    			expect(db_user.access_locked?).not_to be_truthy
    			expect(db_user.unlock_token).to be_nil
    			expect(db_user.locked_at).to be_nil
    			expect(response.location=~/google/).to be_nil
			end

		end

	end


	context "-- json request -- " do 

		
		context " -- valid api key -- " do 

			it " -- new -- " do 
				
				get new_user_unlock_path,params: {api_key: @ap_key, current_app_id: @c.app_ids[0]}.to_json,headers: @headers
				expect(response.code).to eq("406")

			end

			it " -- create -- " do 

				prev_msg_count = ActionMailer::Base.deliveries.size
				post user_unlock_path,params: {user:{email: @u.email},api_key: @ap_key, current_app_id: @c.app_ids[0]}.to_json,headers: @headers
				
				message = ActionMailer::Base.deliveries[-1].to_s
    			token = nil
      			message.scan(/unlock_token=(?<unlock_token>.*)\"/) do |ll|

      				j = Regexp.last_match
      				token = j[:unlock_token]

      			end
    			new_msg_count = ActionMailer::Base.deliveries.size
    			expect(token).not_to be(nil)
    			expect(new_msg_count - prev_msg_count).to eq(1)
				expect(response.code).to eq("201")

			end	

			it " -- show -- " do 
				@u.send_unlock_instructions
				@u.reload
				message = ActionMailer::Base.deliveries[-1].to_s
    			token = nil
      			message.scan(/unlock_token=(?<unlock_token>.*)\"/) do |ll|

      				j = Regexp.last_match
      				token = j[:unlock_token]

      			end
    			get user_unlock_path,params: {unlock_token: token, api_key: @ap_key, current_app_id: @c.app_ids[0]},headers: @headers
    			@u.reload
    			expect(@u.unlock_token).to be_nil
    			expect(@u.locked_at).to be_nil
				expect(response.code).to eq("201")    			

			end

		end

	end

end