require "rails_helper"

RSpec.describe "session request spec", :type => :request do 

	before(:example) do 

        ActionController::Base.allow_forgery_protection = true
        User.delete_all
        Auth::Client.delete_all
        @u = User.new(attributes_for(:user_confirmed))
        @u.save
        @c = Auth::Client.new(:resource_id => @u.id, :api_key => "test")
        @c.redirect_urls = ["http://www.google.com"]
        @c.app_ids << "test_app_id"
        @c.versioned_create
        @u.client_authentication["test_app_id"] = "test_es"
        @u.save
        @ap_key = @c.api_key
        @headers = { "CONTENT_TYPE" => "application/json" , "ACCEPT" => "application/json", "X-User-Token" => @u.authentication_token, "X-User-Es" => @u.client_authentication["test_app_id"], "X-User-Aid" => @c.app_ids[0]}

	end

        context "-- token authentication tests " do 

                it " - authenticates  ",:focus => true do 
                        get new_topic_path, nil, @headers
                        expect(response.code).to eq("200")
                end

                it " - does not authenticate without es", :focus => true do 
                        @headers["X-User-Es"] = "null"
                        get new_topic_path, nil, @headers
                        expect(response.code).to eq("401")
                end

                it " - does not authenticate without app id", :focus => true do 
                        @headers["X-User-Aid"] = "NULL"
                        get new_topic_path, nil, @headers
                        expect(response.code).to eq("401")     
                end

        end

end