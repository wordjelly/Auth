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
        @ap_key = @c.api_key
        @headers = { "CONTENT_TYPE" => "application/json" , "ACCEPT" => "application/json", "X-User-Token" => @u.authentication_token, "X-User-Es" => @u.es, "X-User-Aid" => @c.app_ids[0]}

	end

        context "-t" do 

                it " - just works " do 
                        get new_topic_path, nil, @headers
                        puts response.code.to_s     
                end

        end

end