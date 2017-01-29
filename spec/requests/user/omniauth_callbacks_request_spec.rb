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
    
    ##REFER TO AUTH/CONFIG/INITIALIZERS/OMNIAUTH.RB - for commented code on how the oauth works for android and the web app.

    #it " -- handles incorrect state  -- " do 


    #end
    context " -- json requests -- " do 
=begin
        it " -- handles invalid id_token -- " do 
           
            OmniAuth.config.test_mode = false
           
            Rails.application.env_config["omniauth.model"] = "omniauth/users/"

            post google_oauth2_omniauth_callback_url(:id_token => "rupert", :state => {:api_key => @c.api_key, :current_app_id => @c.app_ids[0], :path => @c.path}.to_json),OmniAuth.config.mock_auth[:google_oauth2],@headers

            expect(JSON.parse(response.body)).to eql({"failure_message" => "Invalid credentials"})
        end   

        it " -- handles invalid code -- " do 

            OmniAuth.config.test_mode = false
           
            Rails.application.env_config["omniauth.model"] = "omniauth/users/"

            post google_oauth2_omniauth_callback_url(:code => "rupert", :state => {:api_key => @c.api_key, :current_app_id => @c.app_ids[0], :path => @c.path}.to_json),OmniAuth.config.mock_auth[:google_oauth2],@headers

            expect(JSON.parse(response.body)).to eql({"failure_message" => "Invalid credentials"})

        end
=end
        #it " -- handles email id already exists -- " do 

        #end

        it " -- handles error in omni_concern -- " do 
            
            ##THIS TEST PRODUCES AN ERROR IN THE OMNI_COMMON 

            OmniAuth.config.test_mode = true
           
            Rails.application.env_config["omniauth.model"] = "omniauth/users/"

            post google_oauth2_omniauth_callback_url(:id_token => "rupert", :state => {:api_key => @c.api_key, :current_app_id => @c.app_ids[0], :path => @c.path}.to_json),OmniAuth.config.mock_auth[:google_oauth2],@headers
            
            puts response.body.to_s

        end


    end

    context " -- web app requests -- " do 

    end

  end	  

end