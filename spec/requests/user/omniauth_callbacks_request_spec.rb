require "rails_helper"

RSpec.describe "Registration requests", :type => :request do
  before(:all) do 
    User.delete_all
    Auth::Client.delete_all
    @u = User.new(attributes_for(:user_confirmed))
    @u.save
    @c = Auth::Client.new(:resource_id => @u.id, :api_key => "test")
    @c.redirect_urls = ["http://www.google.com"]
    @c.app_ids << "test_app_id"
    @c.path = "omniauth/users/"
    @c.versioned_create
    @u.client_authentication["test_app_id"] = "test_es"
    @u.save
    @ap_key = @c.api_key
    @headers = { "CONTENT_TYPE" => "application/json" , "ACCEPT" => "application/json"}
  end


  context " -- json request to callback url ", :oauth => true do 
    it " -- works --" do 
    OmniAuth.config.test_mode = false
    Rails.application.env_config["omniauth.model"] = "omniauth/users/"

    post google_oauth2_omniauth_callback_url(:access_token => "rupert", :state => {:api_key => @c.api_key, :current_app_id => @c.app_ids[0], :path => @c.path}.to_json),OmniAuth.config.mock_auth[:google_oauth2],@headers
    end

  end
  
  ###THIS TEST IS ONLY APPLICABLE TO FACEBOOK , BECAUSE WE CAN SHARE THE AUTHENTICATION TOKEN BETWEEN THE ANDROID APP AND THE SERVER.

  ##THE ONLY THING IS THAT IN CASE WE ALREADY HAVE A DESKTOP AUTHENTICATION FOR THIS USER, WITH AN ACCESS TOKEN, AND THEN HE TRIES TO AUTHENTICATE WITH ANDROID, OUR SERVER WILL REPLY SAYING THERE IS ALREADY AN ACCOUNT WITH THIS EMAIL.

  ##HOW TO HANDLE THIS SITUATION.
  ##provided that the uid and provider is the same he will simply get signed in.
  ##in that case, he will behave like a signed in user, and we can use the new authentication token, instead, which we are already doing.
  ##so we just need to simulate this one request.
    
  ##for the google tests we have to be able to call the test from java.




	  

end