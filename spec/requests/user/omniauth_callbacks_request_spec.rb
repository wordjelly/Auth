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

        context  " -- google_oauth2 test -- " do 
=begin
            it " -- handles invalid id_token -- " do 
               
                OmniAuth.config.test_mode = false
               

                post google_oauth2_omniauth_callback_url(:id_token => "rupert", :state => {:api_key => @c.api_key, :current_app_id => @c.app_ids[0], :path => @c.path}.to_json),OmniAuth.config.mock_auth[:google_oauth2],@headers

                expect(JSON.parse(response.body)).to eql({"failure_message" => "Invalid credentials"})
            end   


            it " -- handles invalid code -- " do 

                OmniAuth.config.test_mode = false
               

                post google_oauth2_omniauth_callback_url(:code => "rupert", :state => {:api_key => @c.api_key, :current_app_id => @c.app_ids[0], :path => @c.path}.to_json),OmniAuth.config.mock_auth[:google_oauth2],@headers

                expect(JSON.parse(response.body)).to eql({"failure_message" => "Invalid credentials"})

            end

=end
            it " -- redirects to omniauth failure path on any error in omni concern. -- " do 
                
                OmniAuth.config.test_mode = false
=begin
                module OmniAuth
                    module Strategies
                        GoogleOauth2.class_eval do 
                            ##########
                            ##JUST MODIFIED THIS TO RETURN NIL AS AUTH_HASH, SO THAT AN ERROR IS SIMULATED IN THE OMNI_COMMON DEF
                            def auth_hash
                                nil
                            end

                            ##########
                            ##JUST MODIFIED THIS TO RETURN TRUE EVERYWHERE.
                            private
                            def verify_id_token(id_token)
                                puts "called verify id token."
                                true
                            end

                            def verify_hd(access_token)
                                puts "Called verify hd."
                                true
                            end 
                        end
                    end
                end
=end                

                post google_oauth2_omniauth_callback_url(:id_token => "rupert", :state => {:api_key => @c.api_key, :current_app_id => @c.app_ids[0], :path => @c.path}.to_json),OmniAuth.config.mock_auth[:google_oauth2],@headers
                
                expect(response).to redirect_to(omniauth_failure_path("error"))

            end

=begin
            it " -- on visiting omniauth_failure_path(error), responds with json {failure_message: error}" do 
               
                get omniauth_failure_path("error"),nil,@headers

                expect(JSON.parse(response.body)).to eql({"failure_message" => "error"}) 

            end

            ## NO RESOURCE TEST.
            it " -- redirects to omniauth_failure_path and gives failure message of 'no resource' if no resource is specified in the omniauth_callback_request. " do 

                OmniAuth.config.test_mode = false
                
                module OmniAuth
                    module Strategies
                        GoogleOauth2.class_eval do 
                            ##########
                            ##JUST MODIFIED THIS TO RETURN THE GOOGLE_OAUTH2 AUTH HASH.
                            def auth_hash
                                OmniAuth::AuthHash.new({
                                  'provider' => 'google_oauth2',
                                  'uid' => '12345',
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

                post google_oauth2_omniauth_callback_url(:id_token => "rupert", :state => {:api_key => @c.api_key, :current_app_id => @c.app_ids[0], :path => nil}.to_json),OmniAuth.config.mock_auth[:google_oauth2],@headers

                expect(response).to redirect_to(omniauth_failure_path("no_resource"))
            end

            ## CREATES NEW USER IF ID_TOKEN IS VALID.
            it " -- creates new user if id_token is valid, and returns auth_token and es, because client is also correct. -- " do 
                ##WE MODIFY THE VERFIY_ID_TOKEN FUNCTION TO RETURN A VALID ID TOKEN, AND ALSO 
                
                module OmniAuth
                    module Strategies
                        GoogleOauth2.class_eval do 
                            ##########
                            ##JUST MODIFIED THIS TO RETURN THE GOOGLE_OAUTH2 AUTH HASH.
                            def auth_hash
                                OmniAuth::AuthHash.new({
                                  'provider' => 'google_oauth2',
                                  'uid' => '12345',
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
               

                post google_oauth2_omniauth_callback_url(:id_token => "rupert", :state => {:api_key => @c.api_key, :current_app_id => @c.app_ids[0], :path => @c.path}.to_json),OmniAuth.config.mock_auth[:google_oauth2],@headers
                puts response.body.to_s
                ##check that a user was created.
                ##check that identity was created.
                
                u = User.where(:email => "rrphotosoft@gmail.com").first
                expect(u).not_to be_nil
                expect(u.identities).to eql([{"provider"=>"google_oauth2", "uid"=>"12345", "email"=>"rrphotosoft@gmail.com"}])
                expect(JSON.parse(response.body).keys).to match_array(["authentication_token","es"])

            end


            ## IT CANT FIND THE CLIENT PROVIDED, THEN SHOULD RETURN SHIT.
            ## TEST PASSES.
            it " -- not able to find the client, it returns 401 unauthorized. -- " do 
                    
                module OmniAuth
                    module Strategies
                        GoogleOauth2.class_eval do 
                            ##########
                            ##JUST MODIFIED THIS TO RETURN THE GOOGLE_OAUTH2 AUTH HASH.
                            def auth_hash
                                OmniAuth::AuthHash.new({
                                  'provider' => 'google_oauth2',
                                  'uid' => '12345',
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
               

                post google_oauth2_omniauth_callback_url(:id_token => "rupert", :state => {:api_key => @c.api_key, :current_app_id => "asshole", :path => @c.path}.to_json),OmniAuth.config.mock_auth[:google_oauth2],@headers

                expect(response.code).to eql("401")
                expect(response.body).to eql("")
                u = User.where(:email => "rrphotosoft@gmail.com").first
                expect(u).to be_nil
            end        

            it " -- responds with user credentials, and updates access_token and expires at, if a user with same email and identity already exists, and he tries to sign in with oauth, provided that the id_token is valid. -- " do 

                @u1 = User.new(attributes_for(:user_confirmed))
                @u1.email = "test@gmail.com"
                @u1.identities 
                @u1.client_authentication["test_app_id"] = "test_es"
                @u1.access_token = "old_access_token"
                @u1.token_expires_at = Time.now.to_i - 100000
                @u1.identities = [Auth::Identity.new(:provider => 'google_oauth2', :uid => '12345').attributes.except("_id")]
                @u1.version = 1
                @u1.save
                
                
                module OmniAuth
                    module Strategies
                        GoogleOauth2.class_eval do 
                            ##########
                            ##JUST MODIFIED THIS TO RETURN THE GOOGLE_OAUTH2 AUTH HASH.
                            def auth_hash
                                OmniAuth::AuthHash.new({
                                  'provider' => 'google_oauth2',
                                  'uid' => '12345',
                                  'info' => {
                                    'name' => 'mockuser',
                                    'image' => 'mock_user_thumbnail_url',
                                    'email' => 'test@gmail.com'
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
               

                post google_oauth2_omniauth_callback_url(:id_token => "rupert", :state => {:api_key => @c.api_key, :current_app_id => @c.app_ids[0], :path => @c.path}.to_json),OmniAuth.config.mock_auth[:google_oauth2],@headers            

                #puts response.body.to_s
                json_response = JSON.parse(response.body)
                expect(json_response["authentication_token"]).to eql(@u1.authentication_token)
                expect(json_response["es"]).to eql("test_es")
                u = User.find(@u1.id)
                expect(u.token_expires_at).to eql(20000)
                expect(u.access_token).to eql("mock_token")

            end 


            #################################################
            ##
            ##
            ##
            ## CODE TESTS. 
            ##
            ##
            ##
            #################################################


            ## CREATES NEW USER IF CODE IS VALID

            it " -- creates new user if code is valid -- " do 
                ## WE REOPEN AUTH_CODE
                module OmniAuth
                    module Strategies
                        GoogleOauth2.class_eval do 
                            ##########
                            ##JUST MODIFIED THIS TO RETURN THE GOOGLE_OAUTH2 AUTH HASH.
                            def auth_hash
                                
                                OmniAuth::AuthHash.new({
                                  'provider' => 'google_oauth2',
                                  'uid' => '12345',
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

                            private
                            def verify_hd(access_token)
                                true
                            end 
                        end
                    end
                end

                module OAuth2
                    module Strategy
                        AuthCode.class_eval do 
                            def get_token(code, params = {}, opts = {})
                                ::OAuth2::AccessToken.new(@client,"")
                            end
                        end
                    end
                end
        
                OmniAuth.config.test_mode = false

                post google_oauth2_omniauth_callback_url(:code => "rupert", :state => {:api_key => @c.api_key, :current_app_id => @c.app_ids[0], :path => @c.path}.to_json),OmniAuth.config.mock_auth[:google_oauth2],@headers

                u = User.where(:email => "rrphotosoft@gmail.com").first
                expect(u).not_to be_nil
                expect(u.identities).to eql([{"provider"=>"google_oauth2", "uid"=>"12345", "email"=>"rrphotosoft@gmail.com"}])
                expect(JSON.parse(response.body).keys).to match_array(["authentication_token","es"])
            
            end

            it " -- responds with user credentials, if try to create oauth with user who already registered before with same email, updates access_token and token_expires_at -- " do 

                @u1 = User.new(attributes_for(:user_confirmed))
                @u1.email = "test@gmail.com"
                @u1.identities 
                @u1.client_authentication["test_app_id"] = "test_es"
                @u1.access_token = "old_access_token"
                @u1.token_expires_at = Time.now.to_i - 100000
                @u1.identities = [Auth::Identity.new(:provider => 'google_oauth2', :uid => '12345').attributes.except("_id")]
                @u1.version = 1
                @u1.save
                
                
                module OmniAuth
                    module Strategies
                        GoogleOauth2.class_eval do 
                            ##########
                            ##JUST MODIFIED THIS TO RETURN THE GOOGLE_OAUTH2 AUTH HASH.
                            def auth_hash
                                
                                OmniAuth::AuthHash.new({
                                  'provider' => 'google_oauth2',
                                  'uid' => '12345',
                                  'info' => {
                                    'name' => 'mockuser',
                                    'image' => 'mock_user_thumbnail_url',
                                    'email' => 'test@gmail.com'
                                  },
                                  'credentials' => {
                                    'token' => 'mock_token',
                                    'secret' => 'mock_secret',
                                    'expires_at' => 20000
                                  }
                                })
                            end

                            private
                            def verify_hd(access_token)
                                true
                            end 
                        end
                    end
                end

                module OAuth2
                    module Strategy
                        AuthCode.class_eval do 
                            def get_token(code, params = {}, opts = {})
                                ::OAuth2::AccessToken.new(@client,"")
                            end
                        end
                    end
                end

                OmniAuth.config.test_mode = false
               

                post google_oauth2_omniauth_callback_url(:code => "rupert", :state => {:api_key => @c.api_key, :current_app_id => @c.app_ids[0], :path => @c.path}.to_json),OmniAuth.config.mock_auth[:google_oauth2],@headers            

                #puts response.body.to_s
                json_response = JSON.parse(response.body)
                expect(json_response["authentication_token"]).to eql(@u1.authentication_token)
                expect(json_response["es"]).to eql("test_es")
                u = User.find(@u1.id)
                expect(u.token_expires_at).to eql(20000)
                expect(u.access_token).to eql("mock_token")

            end

            it "-- 401 if client not found -- " do 

                module OmniAuth
                    module Strategies
                        GoogleOauth2.class_eval do 
                            ##########
                            ##JUST MODIFIED THIS TO RETURN THE GOOGLE_OAUTH2 AUTH HASH.
                            def auth_hash
                                
                                OmniAuth::AuthHash.new({
                                  'provider' => 'google_oauth2',
                                  'uid' => '12345',
                                  'info' => {
                                    'name' => 'mockuser',
                                    'image' => 'mock_user_thumbnail_url',
                                    'email' => 'test@gmail.com'
                                  },
                                  'credentials' => {
                                    'token' => 'mock_token',
                                    'secret' => 'mock_secret',
                                    'expires_at' => 20000
                                  }
                                })
                            end

                            private
                            def verify_hd(access_token)
                                true
                            end 
                        end
                    end
                end

                module OAuth2
                    module Strategy
                        AuthCode.class_eval do 
                            def get_token(code, params = {}, opts = {})
                                ::OAuth2::AccessToken.new(@client,"")
                            end
                        end
                    end
                end

                OmniAuth.config.test_mode = false

                post google_oauth2_omniauth_callback_url(:code => "rupert", :state => {:api_key => @c.api_key, :current_app_id => "asshole", :path => @c.path}.to_json),OmniAuth.config.mock_auth[:google_oauth2],@headers

                expect(response.code).to eql("401")
                expect(response.body).to eql("")
                u = User.where(:email => "rrphotosoft@gmail.com").first
                expect(u).to be_nil

            end

=end

        end


        context  " -- fb test -- " do 

        end

    end

    context " -- web app requests -- " do 
        ##THESE ARE TAKEN CARE OF IN THE FEATURE SPECS.
    end

  end	  

end