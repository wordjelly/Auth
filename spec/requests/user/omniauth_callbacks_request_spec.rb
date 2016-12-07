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


  context " -- google_oauth_2 ", :oauth => true do
    ###THERE ARE BASICALLY THREE POSSIBILITIES:
    ##1. PARAMS CONTAIN "CODE" - THIS IS DONE WHEN YOU HAVE ASKED THE USER ON AN ANDROID APP, TO GIVE OFFLINE ACCESS. YOU WILL HAVE TO POST THIS CODE TO THE CALLBACK URL, AND THIS SHOULD BE A JSON REQUEST.

    ##2. PARAMS CONTAIN "CODE" + "REDIRECT_URL" - THIS IS THE USUAL WEB APPLICATION FLOW.

    ##3. PARAMS CONTAIN "ACCESS_TOKEN" - THIS IS WHEN WE HAVE ASKED USER ONLY FOR CERTAIN PERMISSIONS, AND SO NOT TOTAL SERVER-SIDE API ACCESS, AND SO IT RETURNS ONLY A USER_ID_TOKEN, WHICH HAS TO BE PASSED INTO THE CALLBACK UNDER THE PARAM_NAME OF ACCESS_TOKEN.

    ##WE HAVE TO TEST POSSIBLITY ONE AND THREE.
    ##FROM THE ANDROID APP.

    it " -- json request to callback url with state built from json encoded client, works --" do 
    OmniAuth.config.test_mode = false
    Rails.application.env_config["omniauth.model"] = "omniauth/users/"

    post google_oauth2_omniauth_callback_url(:access_token => "rupert", :state => {:api_key => @c.api_key, :current_app_id => @c.app_ids[0], :path => @c.path}.to_json),OmniAuth.config.mock_auth[:google_oauth2],@headers
    end

  end

  ##in case of facebook the app_id as long as it is same, then posting the code to the callback endpoint should work out.
    



	  

end