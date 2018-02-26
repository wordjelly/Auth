require "rails_helper"

RSpec.describe "token request spec", :type => :request, token: true do 

	before(:all) do 

                ActionController::Base.allow_forgery_protection = true
                User.delete_all
                Auth::Client.delete_all

                
                Auth.configuration.token_regeneration_time = 1.day
                
                @u = User.new(attributes_for(:user_confirmed))
                @u.save
                @c = Auth::Client.new(:resource_id => @u.id, :api_key => "test")
                @c.redirect_urls = ["http://www.google.com"]
                @c.app_ids << "testappid"
                @c.versioned_create
                @u.client_authentication["testappid"] = "testes"
                @u.save

               

                @ap_key = @c.api_key
                @headers = { "CONTENT_TYPE" => "application/json" , "ACCEPT" => "application/json", "X-User-Token" => @u.authentication_token, "X-User-Es" => @u.client_authentication["testappid"], "X-User-Aid" => @c.app_ids[0]}

                @admin = User.new(attributes_for(:user_confirmed))
                @admin.admin = true
                @admin.client_authentication["testappid"] = "testestoken2"
                
                resp = @admin.save
                #puts "Result of saving admin:"
                #puts resp.to_s


                @admin_headers = { "CONTENT_TYPE" => "application/json" , "ACCEPT" => "application/json", "X-User-Token" => @admin.authentication_token, "X-User-Es" => @admin.client_authentication["testappid"], "X-User-Aid" => "testappid"}
             	
    end

     

        context "-- API JSON token authentication tests " do 

                it " - authenticates  ",:one => true do 
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
                       
                        get new_topic_path, nil, { "CONTENT_TYPE" => "application/json" , "ACCEPT" => "application/json", "X-User-Token" => @u.authentication_token, "X-User-Es" => @u.client_authentication["testappid"]}
                        expect(response.code).to eq("401")     
                end

        end

        context " -- authenticates admin as well as user models -- ", :token_tests => true do 



            it " -- doesnt attempt authentication of admin user if the normal user gets authenticated -- " do 

                 get new_topic_path, nil, @headers
                
                 expect(response.code).to eq("200")

            end


        end

        context " -- token regeneration -- " do 



            it " -- yields changed token on sign in -- ", :ctoken => true do 

                u = User.new(attributes_for(:user_confirmed))
                expect(u.save).to be_truthy
                initial_auth_token = u.authentication_token
                puts "initial authentication token is:"
                puts initial_auth_token.to_s
                params = {user: {login: @u.email, password: "password"}, api_key: @ap_key, current_app_id: @c.app_ids[0]}
                ## from where do you expect this authentication token to come ?
                ## it has to be called on sign in.
                post user_session_path, params.to_json, { "CONTENT_TYPE" => "application/json" , "ACCEPT" => "application/json"}

                expect(response.code).to eq("201")

                user_hash = JSON.parse(response.body)
                expect(user_hash.keys).to match_array(["authentication_token","es"])
                expect(user_hash["authentication_token"]).not_to eq(initial_auth_token)
            end

            it " -- fails to sign in past expiration -- " do 

            end

            it " -- yields changed token on user email update -- " do 

            end

            it " -- yields changed token on user password update -- " do 


            end

        end
        
end