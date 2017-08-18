require "rails_helper"

RSpec.describe "token request spec", :type => :request,topic: true do 

	before(:all) do 

                ActionController::Base.allow_forgery_protection = true
                User.delete_all
                Auth::Client.delete_all
                @u = User.new(attributes_for(:user_confirmed))
                @u.save
                Auth.configuration.token_regeneration_time = 1.day
                @c = Auth::Client.new(:resource_id => @u.id, :api_key => "test")
                @c.redirect_urls = ["http://www.google.com"]
                @c.app_ids << "test_app_id"
                @c.versioned_create
                @u.client_authentication["test_app_id"] = "test_es"
                @u.save

                @ap_key = @c.api_key
                @headers = { "CONTENT_TYPE" => "application/json" , "ACCEPT" => "application/json", "X-User-Token" => @u.authentication_token, "X-User-Es" => @u.client_authentication["test_app_id"], "X-User-Aid" => @c.app_ids[0]}

	end

     

        context "-- API JSON token authentication tests " do 

                it " - authenticates  ",:topic_focus => true do 
                        get new_topic_path, nil, @headers
                        expect(response.code).to eq("200")
                end

                it " - authenticates and sets resource ", :topic_focus => true do 
                        get new_topic_path, nil, @headers
                        expect(assigns(:resource)).to be_truthy      
                end

                it " - does not authenticate without es", :defocus => true do 
                       
                        get new_topic_path, nil, { "CONTENT_TYPE" => "application/json" , "ACCEPT" => "application/json", "X-User-Token" => @u.authentication_token, "X-User-Aid" => @c.app_ids[0]}
                        expect(response.code).to eq("401")
                end

                it " - does not authenticate without app id", :focus => true do 
                       
                        get new_topic_path, nil, { "CONTENT_TYPE" => "application/json" , "ACCEPT" => "application/json", "X-User-Token" => @u.authentication_token, "X-User-Es" => @u.client_authentication["test_app_id"]}
                        expect(response.code).to eq("401")     
                end

        end


        context " -- it sets authentication_token_expires_at alongwith auth token-- " do 

                before(:all) do 
                        $earlier_auth_token = nil
                end

                it " - authenticates and sets resource, with token expires at ", :topic_focus => true do 
                        get new_topic_path, nil, @headers
                        expect(assigns(:resource)).to be_truthy
                        resource = assigns(:resource)
                        expect(resource.authentication_token_expires_at).not_to be_nil  
                end

                it " - doesnt authenticate if token has expired -- " do 

                        Auth.configuration.token_regeneration_time = 1
                        user = User.new(attributes_for(:user_confirmed))
                        user.client_authentication["test_app_id"] = "test_es"
                        user.save
                        $earlier_auth_token = user.authentication_token
                        Auth.configuration.token_regeneration_time = 1.day
                        @headers = { "CONTENT_TYPE" => "application/json" , "ACCEPT" => "application/json", "X-User-Token" => user.authentication_token, "X-User-Es" => user.client_authentication["test_app_id"], "X-User-Aid" => @c.app_ids[0]}                        
                        sleep(2)
                        get new_topic_path, nil, @headers
                        expect(response.code).to eq("401")

                end

                it " -- on signing in with this user , it will return the new authentication token and es -- " do 
                        last_user_created = User.order_by(:confirmation_sent_at => 'desc').first
                        ActionController::Base.allow_forgery_protection = false
                        post user_session_path ,{user: {login: last_user_created.email, password: "password"}}
                        ActionController::Base.allow_forgery_protection = true
                        user_returned = assigns(:user)

                        expect(user_returned.authentication_token).not_to eq($earlier_auth_token)

                        expect(user_returned.authentication_token).not_to be_nil
                        expect(user_returned.authentication_token_expires_at > Time.now.to_i).to be_truthy
                end

                it  " -- subsequently it will sign in using the new authentication token and es -- " do 

                        user = User.order_by(:confirmation_sent_at => 'desc').first
                         ##now use this authentication token and es.
                         @headers = { "CONTENT_TYPE" => "application/json" , "ACCEPT" => "application/json", "X-User-Token" => user.authentication_token, "X-User-Es" => user.client_authentication["test_app_id"], "X-User-Aid" => @c.app_ids[0]}                        
                        
                        get new_topic_path, nil, @headers
                        expect(response.code).to eq("200")

                end

        end

end