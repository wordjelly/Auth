require "rails_helper"

RSpec.describe "password request spec", :type => :request do 

	before(:example) do 
		ActionController::Base.allow_forgery_protection = true
        User.delete_all
        Auth::Client.delete_all
        @u = User.new(attributes_for(:user_confirmed))
        @u.save
        @c = Auth::Client.where(:resource_id => @u.id).first
	    @c.api_key = "test"
	    @c.redirect_urls = ["http://www.google.com"]
	    @c.app_ids << "test_app_id"
	    @c.versioned_update
	    @ap_key = @c.api_key
        @headers = { "CONTENT_TYPE" => "application/json" , "ACCEPT" => "application/json", "X-User-Token" => @u.authentication_token, "X-User-Es" => @u.es}

	end

	after(:example) do 
		User.delete_all
      	Auth::Client.delete_all
	end

	context "-- web app requests" do 

		before(:example) do 

			ActionController::Base.allow_forgery_protection = false

		end

	 	context "-- no api key" do 

	 		it "-- get request is successfull" do 

	 			get new_user_password_path,{}
				expect(response.code).to eq("200")				

	 		end

	 		it "-- create request is successfull" do 

	 			post user_password_path,{user: {email: @u.email}}
				expect(response.code).to eq("302")
				expect(response).to redirect_to(new_user_session_path)
				
				

	 		end

	 		it "-- update request is successfull" do 
	 			
	 			old_password = @u.encrypted_password
	 			post user_password_path, user: {email: @u.email}
      			message = ActionMailer::Base.deliveries[-1].to_s
    			rpt_index = message.index("reset_password_token")+"reset_password_token".length+1
    			reset_password_token = message[rpt_index...message.index("\"", rpt_index)]
    			put user_password_path, user: {
			      reset_password_token: reset_password_token, 
			      password: "newpassword", 
			      password_confirmation: "newpassword",
			    }
			    @u.reload
			    expect(@u.encrypted_password).not_to  eq(old_password)
			    expect(@u.errors.full_messages).to be_empty 
	 		
	 		end

	 	end

	 	context "-- valid api key + valid redirect url" do 


	 		it "-- get request does not redirect to redirect url" do 

	 			get new_user_password_path,{redirect_url: "http://www.google.com", api_key: @ap_key, current_app_id: @c.app_ids[0]}
	 			expect(session[:client]).not_to be_nil
	 			expect(session[:redirect_url]).not_to be_nil
				expect(response.code).to eq("200")		

	 		end

	 		it " -- create request does not redirect to redirect url" do 

	 			post user_password_path,{user: {email: @u.email}, redirect_url: "http://www.google.com", api_key: @ap_key, current_app_id: @c.app_ids[0]}
	 			expect(session[:client]).not_to be_nil
	 			expect(session[:redirect_url]).not_to be_nil
				expect(response.code).to eq("302")
				expect(response).to redirect_to(new_user_session_path)

	 		end


	 		it "-- update request does not redirect to redirect url" do 
	 			
	 			old_password = @u.encrypted_password
	 			post user_password_path, user: {email: @u.email}, current_app_id: @c.app_ids[0], redirect_url: "http://www.google.com"
      			message = ActionMailer::Base.deliveries[-1].to_s
    			rpt_index = message.index("reset_password_token")+"reset_password_token".length+1
    			reset_password_token = message[rpt_index...message.index("\"", rpt_index)]
    			
    			put user_password_path, {user: {
			      reset_password_token: reset_password_token, 
			      password: "newpassword", 
			      password_confirmation: "newpassword",
			    }, redirect_url: "http://www.google.com", api_key: @ap_key}
			    @u.reload
			    expect(@u.encrypted_password).not_to  eq(old_password)
			    expect(response).to redirect_to(root_path)
			    expect(@u.errors.full_messages).to be_empty 

	 		end

	 	end

	end

	context "-- json requests " do 

		context "-- no api key" do 

			it "-- get request returns not authorized" do
				get new_user_password_path,nil,@headers
        		expect(response.code).to eq("406")
        	end


        	it "-- create request returns not authorized" do 
        		post user_password_path,{user: {email: @u.email}}.to_json,@headers
        		expect(response.code).to eq("401")
        	end


        	it "-- update request returns not authorized" do 
        		old_password = @u.encrypted_password
        		ActionController::Base.allow_forgery_protection = false
	 			post user_password_path,{user: {email: @u.email}}
	 			ActionController::Base.allow_forgery_protection = true
      			message = ActionMailer::Base.deliveries[-1].to_s
    			rpt_index = message.index("reset_password_token")+"reset_password_token".length+1
    			reset_password_token = message[rpt_index...message.index("\"", rpt_index)]
    			put user_password_path, {user: {
			      reset_password_token: reset_password_token, 
			      password: "newpassword", 
			      password_confirmation: "newpassword",
			    }}.to_json,@headers
			    expect(response.code).to eq("401")
        	end


		end

		context "-- valid api key" do 

			it "-- get request succeeds" do
				get new_user_password_path,{api_key: @ap_key, current_app_id: @c.app_ids[0]},@headers
        		expect(response.code).to eq("406")
        	end


        	it "-- create request succeeds" do 
        		post user_password_path,{user: {email: @u.email}, current_app_id: @c.app_ids[0] ,api_key: @ap_key}.to_json,@headers
        		expect(response.code).to eq("201")

        	end

        	it "-- update request succeeds" do 
        		
        		old_password = @u.encrypted_password
	 			post user_password_path,{user: {email: @u.email}, current_app_id: @c.app_ids[0], api_key: @ap_key}.to_json,@headers
      			message = ActionMailer::Base.deliveries[-1].to_s
    			rpt_index = message.index("reset_password_token")+"reset_password_token".length+1
    			reset_password_token = message[rpt_index...message.index("\"", rpt_index)]
    			put user_password_path, {user: {
			      reset_password_token: reset_password_token, 
			      password: "newpassword", 
			      password_confirmation: "newpassword",
			    }, redirect_url: "http://www.google.com", api_key: @ap_key}.to_json,@headers
			    @u.reload
			    expect(@u.encrypted_password).not_to  eq(old_password)
			    expect(@u.errors.full_messages).to be_empty 

        	end

		end

	end

end
