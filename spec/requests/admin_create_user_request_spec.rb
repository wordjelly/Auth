require "rails_helper"

RSpec.describe "cart item request spec",:cart_item => true,:shopping => true, :type => :request do 

	before(:all) do 
        ActionController::Base.allow_forgery_protection = false
        User.delete_all
        Auth::Client.delete_all
        
        ## THIS PRODUCT IS USED IN THE CART_ITEM FACTORY, TO 
        @u = User.new(attributes_for(:user_confirmed))
        @u.save

        @c = Auth::Client.new(:resource_id => @u.id, :api_key => "test", :app_ids => ["test_app_id"])
        @c.redirect_urls = ["http://www.google.com"]
        @c.versioned_create
        @u.client_authentication["test_app_id"] = "test_es_token"
        @u.save
        @ap_key = @c.api_key
        @headers = { "CONTENT_TYPE" => "application/json" , "ACCEPT" => "application/json", "X-User-Token" => @u.authentication_token, "X-User-Es" => @u.client_authentication["test_app_id"], "X-User-Aid" => "test_app_id"}
        


        ### CREATE ONE ADMIN USER

        ### It will use the same client as the user.
        @admin = Admin.new(attributes_for(:admin_confirmed))
        @admin.client_authentication["test_app_id"] = "test_es_token"
        @admin.save
        @admin_headers = { "CONTENT_TYPE" => "application/json" , "ACCEPT" => "application/json", "X-Admin-Token" => @admin.authentication_token, "X-Admin-Es" => @admin.client_authentication["test_app_id"], "X-Admin-Aid" => "test_app_id"}

        ## add this line to stub the otp api calls, while running the tests.
        Auth.configuration.stub_otp_api_calls = true
        
    end

    context  " -- json requests -- " do 

        context " -- create user with mobile -- ", :admin_create_user_with_mobile do 

            before(:example) do 
                u = User.where(:additional_login_param => "9561137096")
                u.first.delete if u.first
                $redis.flushall
            end
            
            it  " -- creates user and sends otp -- " do 

                post admin_create_users_path,{user: {:additional_login_param => "9561137096"},:api_key => @ap_key, :current_app_id => "test_app_id"}.to_json, @admin_headers
                
                user_created = assigns(:auth_user)
                
                expect(user_created).not_to be_nil
                expect(user_created.errors).to be_empty

                session_id = get_otp_session_id(user_created)
                expect(session_id).not_to be_nil
                expect(response.code).to eq("201")
                response_body = JSON.parse(response.body)
                expect(response_body).to eq({"nothing" => true})

            end

            it  " -- resends the otp, if required -- ", :prob => true do 
                
                user_created = create_user_with_mobile
                initially_sent_otp = get_otp_session_id(user_created)
                
                get send_sms_otp_url({:resource => "users",:user => {:additional_login_param => user_created.additional_login_param},:api_key => @ap_key, :current_app_id => "test_app_id"}),nil,{ "CONTENT_TYPE" => "application/json" , "ACCEPT" => "application/json"}

                new_otp = get_otp_session_id(user_created)

                expect(new_otp).not_to eq(initially_sent_otp)
                expect(new_otp).not_to be_nil
                response_body = JSON.parse(response.body)
                expect(response_body).to eq({"nothing" => true})
            end

            it  " -- verifies the otp, and sends reset password link on success -- " do 

                

            end

            it " -- can resend the password reset link if required -- " do 

            end

            it " -- does not send the reset password link on failure of verification -- " do 

            end

            it " -- does not send the reset password link if the user subsequently changes his mobile number -- " do 

            end

        end

    end

end