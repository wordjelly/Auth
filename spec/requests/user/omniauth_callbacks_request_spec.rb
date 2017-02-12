require "rails_helper"

RSpec.describe "Omniauth requests", :type => :request, :omniauth_requests => true do
  


  context " -- google_oauth_2 ", :oauth => true do
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
    ##REFER TO AUTH/CONFIG/INITIALIZERS/OMNIAUTH.RB - for commented code on how the oauth works for android and the web app.

    

    context " -- json requests -- " do 

        context  " -- google_oauth2 test -- ", single: true do 


            it " -- handles invalid id_token -- " do 
               
                OmniAuth.config.test_mode = false
               

                post google_oauth2_omniauth_callback_url(:id_token => "rupert", :state => {:api_key => @c.api_key, :current_app_id => @c.app_ids[0], :path => @c.path}.to_json),nil,@headers

                expect(JSON.parse(response.body)).to eql({"failure_message" => "Invalid credentials"})
            end   


            it " -- handles invalid code -- " do 

                OmniAuth.config.test_mode = false
               

                post google_oauth2_omniauth_callback_url(:code => "rupert", :state => {:api_key => @c.api_key, :current_app_id => @c.app_ids[0], :path => @c.path}.to_json),nil,@headers

                expect(JSON.parse(response.body)).to eql({"failure_message" => "Invalid credentials"})

            end


            it " -- redirects to omniauth failure path on any error in omni concern. -- ", module_support: true do 
                
                OmniAuth.config.test_mode = false

                google_oauth2_nil_hash
               
                post google_oauth2_omniauth_callback_url(:id_token => "rupert", :state => {:api_key => @c.api_key, :current_app_id => @c.app_ids[0], :path => @c.path}.to_json),nil,@headers
                
                expect(response).to redirect_to(omniauth_failure_path("error"))

            end


       

            ## NO RESOURCE TEST.
            it " -- redirects to omniauth_failure_path and gives failure message of 'no resource' if no resource is specified in the omniauth_callback_request. " do 

                OmniAuth.config.test_mode = false
                
                google_oauth2_verify_token_true_verify_hd_true 
                    
                post google_oauth2_omniauth_callback_url(:id_token => "rupert", :state => {:api_key => @c.api_key, :current_app_id => @c.app_ids[0], :path => nil}.to_json),nil,@headers

                expect(response).to redirect_to(omniauth_failure_path("no_resource"))
            end


            ## CREATES NEW USER IF ID_TOKEN IS VALID.
            it " -- creates new user if id_token is valid, and returns auth_token and es, because client is also correct. -- " do 
                ##WE MODIFY THE VERFIY_ID_TOKEN FUNCTION TO RETURN A VALID ID TOKEN, AND ALSO 

                google_oauth2_verify_token_true_verify_hd_true

                OmniAuth.config.test_mode = false
               

                post google_oauth2_omniauth_callback_url(:id_token => "rupert", :state => {:api_key => @c.api_key, :current_app_id => @c.app_ids[0], :path => @c.path}.to_json),nil,@headers
                #puts response.body.to_s
                ##check that a user was created.
                ##check that identity was created.
                
                u = User.where(:email => "rrphotosoft@gmail.com").first
                expect(u).not_to be_nil
                expect(u.identities).to eql([{"provider"=>"google_oauth2", "uid"=>"12345", "email"=>"rrphotosoft@gmail.com", "access_token" =>"mock_token", "token_expires_at" => 20000 }])
                expect(JSON.parse(response.body).keys).to match_array(["authentication_token","es"])

            end


            ## IT CANT FIND THE CLIENT PROVIDED, THEN SHOULD RETURN SHIT.
            ## TEST PASSES.
            it " -- not able to find the client, it returns 401 unauthorized. -- " do 
                    
                google_oauth2_verify_token_true_verify_hd_true

                OmniAuth.config.test_mode = false
               

                post google_oauth2_omniauth_callback_url(:id_token => "rupert", :state => {:api_key => @c.api_key, :current_app_id => "asshole", :path => @c.path}.to_json),nil,@headers

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
                access_token = "old_access_token"
                token_expires_at = Time.now.to_i - 100000
                @u1.identities = [Auth::Identity.new(:provider => 'google_oauth2', :uid => '12345', :access_token => "old_access_token", :token_expires_at => token_expires_at).attributes.except("_id")]
                @u1.version = 1
                @u1.save
                
                
                google_oauth2_verify_token_true_verify_hd_true

                OmniAuth.config.test_mode = false
               

                post google_oauth2_omniauth_callback_url(:id_token => "rupert", :state => {:api_key => @c.api_key, :current_app_id => @c.app_ids[0], :path => @c.path}.to_json),nil,@headers            

                #puts response.body.to_s
                json_response = JSON.parse(response.body)
                expect(json_response["authentication_token"]).to eql(@u1.authentication_token)
                expect(json_response["es"]).to eql("test_es")
                u = User.find(@u1.id)
                expect(u.identities[0]["token_expires_at"]).to eql(20000)
                expect(u.identities[0]["access_token"]).to eql("mock_token")

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
                google_oauth2_verify_hd_true
                google_oauth2_auth_code_get_token
                
                OmniAuth.config.test_mode = false

                post google_oauth2_omniauth_callback_url(:code => "rupert", :state => {:api_key => @c.api_key, :current_app_id => @c.app_ids[0], :path => @c.path}.to_json),nil,@headers

                u = User.where(:email => "rrphotosoft@gmail.com").first
                expect(u).not_to be_nil
                expect(u.identities).to eql([{"provider"=>"google_oauth2", "uid"=>"12345", "email"=>"rrphotosoft@gmail.com", "access_token" => "mock_token", "token_expires_at" => 20000}])
                expect(JSON.parse(response.body).keys).to match_array(["authentication_token","es"])
            
            end

            it " -- responds with user credentials, if try to create oauth with user who already registered before with same email, updates access_token and token_expires_at -- " do 

                @u1 = User.new(attributes_for(:user_confirmed))
                @u1.email = "test@gmail.com"
                @u1.identities 
                @u1.client_authentication["test_app_id"] = "test_es"
                access_token = "old_access_token"
                token_expires_at = Time.now.to_i - 100000
                @u1.identities = [Auth::Identity.new(:provider => 'google_oauth2', :uid => '12345', :access_token => "old_access_token", :token_expires_at => token_expires_at).attributes.except("_id")]
                @u1.version = 1
                @u1.save
                
                google_oauth2_verify_hd_true
                google_oauth2_auth_code_get_token

                OmniAuth.config.test_mode = false
               

                post google_oauth2_omniauth_callback_url(:code => "rupert", :state => {:api_key => @c.api_key, :current_app_id => @c.app_ids[0], :path => @c.path}.to_json),nil,@headers            

                #puts response.body.to_s
                json_response = JSON.parse(response.body)
                expect(json_response["authentication_token"]).to eql(@u1.authentication_token)
                expect(json_response["es"]).to eql("test_es")
                u = User.find(@u1.id)
                expect(u.identities[0]["token_expires_at"]).to eql(20000)
                expect(u.identities[0]["access_token"]).to eql("mock_token")

            end

            it " -- creates a client after , new user is created using oauth -- " do 

                ## WE REOPEN AUTH_CODE
                google_oauth2_verify_hd_true
                google_oauth2_auth_code_get_token
            
                OmniAuth.config.test_mode = false

                post google_oauth2_omniauth_callback_url(:code => "rupert", :state => {:api_key => @c.api_key, :current_app_id => @c.app_ids[0], :path => @c.path}.to_json),nil,@headers

                u = User.where(:email => "rrphotosoft@gmail.com").first
                expect(u).not_to be_nil

                client = Auth::Client.where(:resource_id => u.id)
                expect(client).not_to be_nil

            end

        end

        context  " -- fb test -- ", single: true do 

            it " -- handles invalid exchange_token -- " do 
               
                OmniAuth.config.test_mode = false

                post facebook_omniauth_callback_url(:fb_exchange_token => "rupert", :state => {:api_key => @c.api_key, :current_app_id => @c.app_ids[0], :path => @c.path}.to_json),nil,@headers

                expect(JSON.parse(response.body)).to eql({"failure_message" => "Invalid credentials"})
            end   

            it " -- creates a new user if the fb_exchange_token is valid, and returns auth_token and es -- " do 

                facebook_oauth2_verify_fb_ex_token

                OmniAuth.config.test_mode = false

                post facebook_omniauth_callback_url(:fb_exchange_token => "rupert", :state => {:api_key => @c.api_key, :current_app_id => @c.app_ids[0], :path => @c.path}.to_json),nil,@headers

                u = User.where(:email => "rrphotosoft@gmail.com").first
                expect(u).not_to be_nil
                expect(u.identities).to eql([{"provider"=>"facebook", "uid"=>"12345", "email"=>"rrphotosoft@gmail.com", "access_token" =>"mock_token", "token_expires_at" => 20000 }])
                expect(JSON.parse(response.body).keys).to match_array(["authentication_token","es"])

            end

            it " -- redirects to omniauth failure path on any error in omni concern. -- " do 
                
                OmniAuth.config.test_mode = false

                facebook_oauth2_nil_hash

                post facebook_omniauth_callback_url(:fb_exchange_token => "rupert", :state => {:api_key => @c.api_key, :current_app_id => @c.app_ids[0], :path => @c.path}.to_json),nil,@headers
                
                expect(response).to redirect_to(omniauth_failure_path("error"))

            end

            ## NO RESOURCE TEST.
            it " -- redirects to omniauth_failure_path and gives failure message of 'no resource' if no resource is specified in the omniauth_callback_request. " do 

                OmniAuth.config.test_mode = false
                
                facebook_oauth2_verify_fb_ex_token

                post facebook_omniauth_callback_url(:fb_exchange_token => "rupert", :state => {:api_key => @c.api_key, :current_app_id => @c.app_ids[0], :path => nil}.to_json),nil,@headers

                expect(response).to redirect_to(omniauth_failure_path("no_resource"))
            end

        end

    end

  end

  context " -- multi provider tests -- ", single:true do 

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

    ###
    ## THESE TESTS MUST BE RUN IN SEQUENCE, THEY ARE RELATED.
    ###

        it " -- creates google_oauth2 user -- " do 

            OmniAuth.config.test_mode = false
            
            google_oauth2_verify_token_true_verify_hd_true 

            post google_oauth2_omniauth_callback_url(:id_token => "rupert", :state => {:api_key => @c.api_key, :current_app_id => @c.app_ids[0], :path => @c.path}.to_json),nil,@headers

        end

        it " -- creates facebook user with the same email -- " do 

            facebook_oauth2_verify_fb_ex_token

            OmniAuth.config.test_mode = false

            existing_user_with_email = User.where(:email => "rrphotosoft@gmail.com").first
            

            post facebook_omniauth_callback_url(:fb_exchange_token => "rupert", :state => {:api_key => @c.api_key, :current_app_id => @c.app_ids[0], :path => @c.path}.to_json),nil,@headers

            u = User.where(:email => "rrphotosoft@gmail.com").first
            
            expect(u).not_to be_nil
            expect(u.identities.include?({"provider"=>"facebook", "uid"=>"12345", "email"=>"rrphotosoft@gmail.com", "access_token" =>"mock_token", "token_expires_at" => 20000 })).to be_truthy
            expect(u.identities.include?({"provider"=>"google_oauth2", "uid"=>"12345", "email"=>"rrphotosoft@gmail.com", "access_token" =>"mock_token", "token_expires_at" => 20000 })).to be_truthy
        end

        it " -- can sign in subsequently with google, updating access_token and es. -- " do 

            google_oauth2_verify_token_true_verify_hd_true

            OmniauthMacros::MOCK_TOKEN = 'new_mock_token'
            OmniauthMacros::EXPIRES_AT = 40000

            OmniAuth.config.test_mode = false
           

            post google_oauth2_omniauth_callback_url(:id_token => "rupert", :state => {:api_key => @c.api_key, :current_app_id => @c.app_ids[0], :path => @c.path}.to_json),nil,@headers

            u = User.where(:email => "rrphotosoft@gmail.com").first
            
           
            expect(u.identities.include?({"provider"=>"google_oauth2", "uid"=>"12345", "email"=>"rrphotosoft@gmail.com", "access_token" =>"new_mock_token", "token_expires_at" => 40000 })).to be_truthy

        end

        it " -- can sign in subsequently with facebook, updating access_token and es. -- " do 
                            
            facebook_oauth2_verify_fb_ex_token

            OmniAuth.config.test_mode = false
            OmniauthMacros::MOCK_TOKEN = 'new_mock_token'
            OmniauthMacros::EXPIRES_AT = 40000

            post facebook_omniauth_callback_url(:fb_exchange_token => "rupert", :state => {:api_key => @c.api_key, :current_app_id => @c.app_ids[0], :path => @c.path}.to_json),nil,@headers

            u = User.where(:email => "rrphotosoft@gmail.com").first
            
           
            expect(u.identities.include?({"provider"=>"facebook", "uid"=>"12345", "email"=>"rrphotosoft@gmail.com", "access_token" =>"new_mock_token", "token_expires_at" => 40000 })).to be_truthy

        end

  end	

  context " -- confirmed_at tests --- " do 

    context " -- repeated oauth sign in , does not update confirmed_at -- " do 
        
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
            @confirmed_at_times = []
        end

        it " -- first create user with google_oauth2 -- " do 
            OmniAuth.config.test_mode = false
            
            google_oauth2_verify_token_true_verify_hd_true 

            post google_oauth2_omniauth_callback_url(:id_token => "rupert", :state => {:api_key => @c.api_key, :current_app_id => @c.app_ids[0], :path => @c.path}.to_json),nil,@headers

            user_created = User.where(:email => "rrphotosoft@gmail.com").first
            @confirmed_at_times << user_created.confirmed_at

        end

        it " -- now sign in again, confirmed_at should not change  -- " do 
            sleep(4)
            OmniAuth.config.test_mode = false
            
            google_oauth2_verify_token_true_verify_hd_true 

            post google_oauth2_omniauth_callback_url(:id_token => "rupert", :state => {:api_key => @c.api_key, :current_app_id => @c.app_ids[0], :path => @c.path}.to_json),nil,@headers
            user_signed_in = User.where(:email => "rrphotosoft@gmail.com").first

            @confirmed_at_times << user_signed_in.confirmed_at
            expect(@confirmed_at_times.uniq.size).to eql(1)         
        end
    end


    context " -- sign in with different identities, does not update confirmed_at -- " do 

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
            @confirmed_at_times = []
        end

        it " -- first create user with google_oauth2 -- " do 
            OmniAuth.config.test_mode = false
            
            google_oauth2_verify_token_true_verify_hd_true 

            post google_oauth2_omniauth_callback_url(:id_token => "rupert", :state => {:api_key => @c.api_key, :current_app_id => @c.app_ids[0], :path => @c.path}.to_json),nil,@headers

            user_created = User.where(:email => "rrphotosoft@gmail.com").first
            @confirmed_at_times << user_created.confirmed_at

        end

        it " -- subsequently signs in with facebook identity --- " do 
            sleep(5)
            facebook_oauth2_verify_fb_ex_token

            OmniAuth.config.test_mode = false

            existing_user_with_email = User.where(:email => "rrphotosoft@gmail.com").first
            

            post facebook_omniauth_callback_url(:fb_exchange_token => "rupert", :state => {:api_key => @c.api_key, :current_app_id => @c.app_ids[0], :path => @c.path}.to_json),nil,@headers

            u = User.where(:email => "rrphotosoft@gmail.com").first
            @confirmed_at_times << u.confirmed_at
            expect(@confirmed_at_times.uniq.size).to eql(1)         

        end


    end


  end  

end