require "rails_helper"

RSpec.describe "password request spec", :type => :request do 

	before(:example) do 
		ActionController::Base.allow_forgery_protection = true
        User.delete_all
        Auth::Client.delete_all
        @u = User.new(attributes_for(:user))
        @u.save
        @c = Auth::Client.new(:user_id => @u.id, :api_key => "test")
        @c.redirect_urls = ["http://www.google.com"]
        @c.versioned_create
        @ap_key = @c.api_key
        @headers = { "CONTENT_TYPE" => "application/json" , "ACCEPT" => "application/json", "X-User-Token" => @u.authentication_token, "X-User-Es" => @u.es}

	end

	after(:example) do 
		session.delete(:client)
		session.delete(:redirect_url)
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
=begin
	 		it "-- update request is successfull" do 

	 		end
=end
	 	end

	 	context "-- valid api key + valid redirect url" do 

=begin
	 		it "-- get request does not redirect to redirect url" do 


	 		end

	 		it " -- create request does not redirect to redirect url" do 

	 		end

	 		it "-- update request does not redirect to redirect url" do 


	 		end
=end
	 	end

	end

	context "-- json requests " do 

	end

end