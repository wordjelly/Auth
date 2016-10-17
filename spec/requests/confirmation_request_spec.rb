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

			end

			it "-- create request is successfull" do 

			end

			it "-- show request is successfull" do 


			end

		end

		context "-- valid api key + redirect url" do 

			it "-- get request, client created, but no redirection" do 

			end

			it "-- create request, client created, but no redirection" do 


			end

			it "-- show request, client created, but no redirection" do 


			end

		end

	end

	context "-- json requests " do 

		context "-- no api key" do 

			it "-- get request returns 406" do 

			end

			it "-- create request returns not authenticated" do 

			end

			it "-- show request returns not authenticated" do 


			end

		end


		context "-- valid api key" do 

			it "-- get request returns 406" do 

			end

			it "-- create request successfull" do 

			end

			it "-- show request succesfull" do 

			end

		end

	end

end