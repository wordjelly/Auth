require "rails_helper"

RSpec.describe "Omniauth requests", :type => :request do
  before(:each) do 
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


        it " -- redirects to omniauth failure path on any error in omni concern. -- " do 
            
            ##THIS TEST PRODUCES AN ERROR IN THE OMNI_concern def #omni_corner.rb#omni_common

            OmniAuth.config.test_mode = true
           
            Rails.application.env_config["omniauth.model"] = "omniauth/users/"

            post google_oauth2_omniauth_callback_url(:id_token => "rupert", :state => {:api_key => @c.api_key, :current_app_id => @c.app_ids[0], :path => @c.path}.to_json),OmniAuth.config.mock_auth[:google_oauth2],@headers
            
            expect(response).to redirect_to(omniauth_failure_path("error"))

        end


        it " -- on visiting omniauth_failure_path(error), responds with json {failure_message: error}" do 

            get omniauth_failure_path("error"),nil,@headers

            expect(JSON.parse(response.body)).to eql({"failure_message" => "error"}) 

        end

        ## NO RESOURCE TEST.
        it " -- redirects to omniauth_failure_path and gives failure message of 'no resource' if no resource is specified in the omniauth_callback_request. " do 

            OmniAuth.config.test_mode = true
           
            Rails.application.env_config["omniauth.model"] = nil

            post google_oauth2_omniauth_callback_url(:id_token => "rupert", :state => {:api_key => @c.api_key, :current_app_id => @c.app_ids[0], :path => @c.path}.to_json),OmniAuth.config.mock_auth[:google_oauth2],@headers

            expect(response).to redirect_to(omniauth_failure_path("no_resource"))
        end
=end

        ## CREATES NEW USER IF ID_TOKEN IS VALID.
        it " -- creates new user if id_token is valid -- " do 
            ##WE MODIFY THE VERFIY_ID_TOKEN FUNCTION TO RETURN A VALID ID TOKEN, AND ALSO 
            

            module OmniAuth
                module Strategies
                    GoogleOauth2.class_eval do 
                        ##########
                        ##JUST MODIFIED THIS TO RETURN THE GOOGLE_OAUTH2 AUTH HASH.
                        def auth_hash
                            OmniAuth::AuthHash.new({
                              'provider' => 'google_oauth2',
                              'uid' => '123545',
                              'info' => {
                                'name' => 'mockuser',
                                'image' => 'mock_user_thumbnail_url',
                                'email' => 'rrphotosoft@gmail.com'
                              },
                              'credentials' => {
                                'token' => 'mock_token',
                                'secret' => 'mock_secret',
                                'expires_at' => 20000
                              }
                            })
                        end

                        ##########
                        ##JUST MODIFIED THIS TO RETURN TRUE EVERYWHERE.
                        private
                        def verify_id_token(id_token)
                            true
                        end

                        def verify_hd(access_token)
                            true
                        end 
                    end
                end
            end


            OmniAuth.config.test_mode = false
           
            Rails.application.env_config["omniauth.model"] = "omniauth/users/"

            post google_oauth2_omniauth_callback_url(:id_token => "rupert", :state => {:api_key => @c.api_key, :current_app_id => @c.app_ids[0], :path => @c.path}.to_json),OmniAuth.config.mock_auth[:google_oauth2],@headers

            ##check that a user was created.
            ##check that identity was created.
            u = User.where(:email => "rrphotosoft@gmail.com").first
            expect(u).not_to be_nil
            expect(u.identities).to eql([{"provider"=>"google_oauth2", "uid"=>"123545", "email"=>"rrphotosoft@gmail.com"}])
            puts response.body.to_s
        end

=begin
        ## CREATES NEW USER IF CODE IS VALID
        it " -- creates new user if code is valid -- " do 

        end
=end

        ## RESPONDS WITH USER CREDENTIALS IF USER ALREADY EXISTS, AND CODE IS VALID.
        #it " -- responds with user credentials if user already exists and code is valid -- " do 



        #end

=begin        
        it " -- responds with user credentials if user already exists and id_token is valid -- " do 


        end
=end



    end

    context " -- web app requests -- " do 

    end

  end	  

end