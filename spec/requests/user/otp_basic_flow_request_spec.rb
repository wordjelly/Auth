##THESE TESTS MUST BE RUN IN THE SEQUENCE DEFINED BELOW, i.e AS THEY APPEAR IN THE TEST FILE.
require "rails_helper"

RSpec.describe "OTP flow requests", :otp => true,:authentication => true, :type => :request do
  before(:all) do 
    User.delete_all
    Auth::Client.delete_all
    module Devise

      RegistrationsController.class_eval do

        def sign_up_params
          ##quick hack to make registrations controller accept confirmed_at, because without that there is no way to send in a confirmed admin directly while creating the admin.
          params.require(:user).permit(
            :email, :password, :password_confirmation,
            :confirmed_at, :redirect_url, :api_key, :additional_login_param
          )
        end

      end

    end

  end

  context " -- json requests -- " do 

    before(:all) do 
        ActionController::Base.allow_forgery_protection = true
        User.delete_all
        Auth::Client.delete_all
        @u = User.new(attributes_for(:user_confirmed))
        @u.save
        @c = Auth::Client.new(:resource_id => @u.id, :api_key => "test", :app_ids => ["test_app_id"])
        @c.redirect_urls = ["http://www.google.com"]
        @c.versioned_create
        @u.client_authentication["test_app_id"] = "test_es_token"
        @u.save
        @ap_key = @c.api_key
        @headers = { "CONTENT_TYPE" => "application/json" , "ACCEPT" => "application/json"}
       Auth.configuration.stub_otp_api_calls = true
        
    end


    context " -- basic otp flow --", :basic_otp_flow => true do
        before(:all) do 
            $otp_session_id = nil
        end

        after(:all) do 
            $otp_session_id = nil
        end

        it " -- on creating unconfirmed user with a mobile number, it sends otp -- " do 
            
            post user_registration_path, {user: attributes_for(:user_mobile),:api_key => @ap_key, :current_app_id => "test_app_id"}.to_json, @headers
            @user_created = assigns(:user)
            @cl = assigns(:client)
            user_json_hash = JSON.parse(response.body)
            expect(user_json_hash.keys).to match_array(["nothing"])
        
        end

        it " -- accepts otp at the verify otp endpoint -- " do 

            @last_user_created = User.order_by(:confirmation_sent_at => 'desc').first
            $otp_session_id = $redis.hget(@last_user_created.id.to_s + "_two_factor_sms_otp","otp_session_id")
            
            get verify_otp_url({:resource => "users",:user => {:additional_login_param => @last_user_created.additional_login_param, :otp => $otp_session_id},:api_key => @ap_key, :current_app_id => "test_app_id"}),nil,@headers
            user_json_hash = JSON.parse(response.body)
            
            expect(user_json_hash.keys).to match_array(["nothing"])
        end

        it " -- short polls for verification status, returns verified true", :one_test => true  do    
            @last_user_created = User.order_by(:confirmation_sent_at => 'desc').first
            
            get otp_verification_result_url({:resource => "users",:user => {:additional_login_param => @last_user_created.additional_login_param, :otp => $otp_session_id},:api_key => @ap_key, :current_app_id => "test_app_id"}),nil,@headers
            user_json_hash = JSON.parse(response.body)
            puts user_json_hash.to_s
            expect(user_json_hash["verified"]).to eq(true)
            expect(user_json_hash["resource"]).not_to include("authentication_token","es")
        end

    end


    
    context " -- resend otp flow -- ", :resend_otp => true do 
        before(:all) do 
            $otp_session_id = nil
            User.delete_all
        end

        after(:all) do 
            $otp_session_id = nil
        end
        it " -- on creating unconfirmed user with a mobile number, it sends otp -- " do 
            
            post user_registration_path, {user: attributes_for(:user_mobile),:api_key => @ap_key, :current_app_id => "test_app_id"}.to_json, @headers
            @user_created = assigns(:user)
            @cl = assigns(:client)
            user_json_hash = JSON.parse(response.body)
            expect(user_json_hash.keys).to match_array(["nothing"])
        end

        it "-- resends otp on hitting the resend endpoint " do 
            @last_user_created = User.order_by(:confirmation_sent_at => 'desc').first
            old_session_id = $redis.hget(@last_user_created.id.to_s + "_two_factor_sms_otp","otp_session_id")
            
            get send_sms_otp_url({:resource => "users",:user => {:additional_login_param => @last_user_created.additional_login_param},:api_key => @ap_key, :current_app_id => "test_app_id"}),nil,@headers
            
            new_session_id = $redis.hget(@last_user_created.id.to_s + "_two_factor_sms_otp","otp_session_id")
            
            user_json_hash = JSON.parse(response.body)
           
            expect(user_json_hash.keys).to match_array(["nothing"])
            expect(new_session_id).not_to eq(old_session_id)
        end

        it " -- accepts otp at the verify otp endpoint -- " do 
            @last_user_created = User.order_by(:confirmation_sent_at => 'desc').first
            
            $otp_session_id = $redis.hget(@last_user_created.id.to_s + "_two_factor_sms_otp","otp_session_id")

            get verify_otp_url({:resource => "users",:user => {:additional_login_param => @last_user_created.additional_login_param, :otp => $otp_session_id},:api_key => @ap_key, :current_app_id => "test_app_id"}),nil,@headers
            user_json_hash = JSON.parse(response.body)
            
            expect(user_json_hash.keys).to match_array(["nothing"])
        end

        it " -- short polls for verification status, returns verified true"  do    
            @last_user_created = User.order_by(:confirmation_sent_at => 'desc').first
            session_id = $redis.hget(@last_user_created.id.to_s + "_two_factor_sms_otp","otp_session_id")
            get otp_verification_result_url({:resource => "users",:user => {:additional_login_param => @last_user_created.additional_login_param, :otp => $otp_session_id},:api_key => @ap_key, :current_app_id => "test_app_id"}),nil,@headers
            user_json_hash = JSON.parse(response.body)
            
            expect(user_json_hash["verified"]).to eq(true)
            expect(user_json_hash["resource"]).not_to include("authentication_token","es")
        end

        it " -- does not return verified true if there are errors from the short polling endpoint " do 
            @last_user_created = User.order_by(:confirmation_sent_at => 'desc').first
            $redis.hset(@last_user_created.id.to_s + "_two_factor_sms_otp","error","some bloody error")
            get otp_verification_result_url({:resource => "users",:user => {:_id => @last_user_created.id.to_s, :otp => $otp_session_id},:api_key => @ap_key, :current_app_id => "test_app_id"}),nil,@headers
            user_json_hash = JSON.parse(response.body)
            expect(user_json_hash["resource"].keys).not_to include("authentication_token","es") 
            expect(user_json_hash["verified"]).to eq(false)

        end

        it " -- processes short polling endpoint without api_key and current_app_id " do 
            @last_user_created = User.order_by(:confirmation_sent_at => 'desc').first
            
            get otp_verification_result_url({:resource => "users",:user => {:_id => @last_user_created.id.to_s, :otp => $otp_session_id},:api_key => @ap_key}),nil,@headers
            
            
            expect(response.body).not_to be_empty

        end

    end

    
    context " -- invalid otp flow -- " do 
        before(:all) do 
            $otp_session_id = nil
            User.delete_all
        end

        after(:all) do 
            $otp_session_id = nil
        end
        after(:example) do 
            ##reset everything, so that things dont spillover into other examples.
            Auth.configuration.simulate_invalid_otp = false
        end
        it " -- on creating unconfirmed user with a mobile number, it sends otp -- " do 
            
            post user_registration_path, {user: attributes_for(:user_mobile),:api_key => @ap_key, :current_app_id => "test_app_id"}.to_json, @headers
            @user_created = assigns(:user)
            @cl = assigns(:client)
            user_json_hash = JSON.parse(response.body)
            expect(user_json_hash.keys).to match_array(["nothing"])
        end

        it " -- accepts otp at the verify otp endpoint -- " do 
            Auth.configuration.simulate_invalid_otp = true
            @last_user_created = User.order_by(:confirmation_sent_at => 'desc').first
            $otp_session_id = $redis.hget(@last_user_created.id.to_s + "_two_factor_sms_otp","otp_session_id")
            get verify_otp_url({:resource => "users",:user => {:additional_login_param => @last_user_created.additional_login_param, :otp => $otp_session_id},:api_key => @ap_key, :current_app_id => "test_app_id"}),nil,@headers
            user_json_hash = JSON.parse(response.body)
            
            expect(user_json_hash.keys).to match_array(["nothing"])
        end

        it " -- short polls for verification status returns verified false"  do    
            @last_user_created = User.order_by(:confirmation_sent_at => 'desc').first
            $otp_session_id = $redis.hget(@last_user_created.id.to_s + "_two_factor_sms_otp","otp_session_id")
            get otp_verification_result_url({:resource => "users",:user => {:additional_login_param => @last_user_created.additional_login_param, :otp => $otp_session_id},:api_key => @ap_key, :current_app_id => "test_app_id"}),nil,@headers
            user_json_hash = JSON.parse(response.body)
            expect(user_json_hash["verified"]).to eq(false) 
            expect(user_json_hash["resource"]).not_to include("authentication_token","es")
        end        

    
    end

    context " -- forgot password flow with confirmed email --" do 
        ##so basically we have to call send sms otp with an intent.
        ##suppose we call it without an intent, then what happens?
        ##when we call the subsequent call, then ?
        before(:all) do 
            $otp_session_id = nil
            User.delete_all
        end

        after(:all) do 
            $otp_session_id = nil
           
        end

        it " -- on creating unconfirmed user with a mobile number, it sends otp -- " do 
            
            post user_registration_path, {user: attributes_for(:user_mobile),:api_key => @ap_key, :current_app_id => "test_app_id"}.to_json, @headers
            @user_created = assigns(:user)
            @cl = assigns(:client)
            user_json_hash = JSON.parse(response.body)
            expect(user_json_hash.keys).to match_array(["nothing"])
        
        end

        it " -- accepts otp at the verify otp endpoint -- " do 

            @last_user_created = User.order_by(:confirmation_sent_at => 'desc').first
            $otp_session_id = $redis.hget(@last_user_created.id.to_s + "_two_factor_sms_otp","otp_session_id")
            
            get verify_otp_url({:resource => "users",:user => {:additional_login_param => @last_user_created.additional_login_param, :otp => $otp_session_id},:api_key => @ap_key, :current_app_id => "test_app_id"}),nil,@headers
            user_json_hash = JSON.parse(response.body)
            
            expect(user_json_hash.keys).to match_array(["nothing"])
        end

        it " -- short polls for verification status, returns verified true"  do    
            @last_user_created = User.order_by(:confirmation_sent_at => 'desc').first
            
           
            get otp_verification_result_url({:resource => "users",:user => {:additional_login_param => @last_user_created.additional_login_param, :otp => $otp_session_id},:api_key => @ap_key, :current_app_id => "test_app_id"}),nil,@headers
            user_json_hash = JSON.parse(response.body)
            
            expect(user_json_hash["verified"]).to eq(true)
            expect(user_json_hash["resource"]).not_to include("authentication_token","es")
        end

        ##we then manually confirm the user.
        it " -- updates the user with a new email address " do 
            @last_user_created = User.order_by(:confirmation_sent_at => 'desc').first
                   
            a = {:id => @last_user_created.id.to_s, :user => {:email => "rihanna@gmail.com", :current_password => 'password'}, api_key: @ap_key, :current_app_id => "test_app_id"}
                   
            put user_registration_path, a.to_json,@headers.merge({"X-User-Token" => @last_user_created.authentication_token, "X-User-Es" => @last_user_created.client_authentication["test_app_id"], "X-User-Aid" => "test_app_id"})
            @user_updated = assigns(:user)
            ##manually confirm the email.
            @last_user_created = User.order_by(:confirmation_sent_at => 'desc').first
            @last_user_created.confirm!
            @last_user_created.save            

            expect(@last_user_created.email).to eq("rihanna@gmail.com")
           # expect(@last_user_created.errors).to be_empty
            expect(response.code).to eq("200")
        end

        it " -- resends sms otp this time with an intent of reset password, " do 

            @last_user_created = User.order_by(:confirmation_sent_at => 'desc').first
           
            
            get send_sms_otp_url({:resource => "users",:user => {:additional_login_param => @last_user_created.additional_login_param},:api_key => @ap_key, :current_app_id => "test_app_id", :intent => "reset_password"}),nil,@headers
            
            user_json_hash = JSON.parse(response.body)
            
        end

        ##now it has to go to verify endpoint again.
        it " -- REVERIFIES OTP at the  verify otp endpoint -- " do 

            @last_user_created = User.order_by(:confirmation_sent_at => 'desc').first
            $otp_session_id = $redis.hget(@last_user_created.id.to_s + "_two_factor_sms_otp","otp_session_id")
            
            get verify_otp_url({:resource => "users",:user => {:additional_login_param => @last_user_created.additional_login_param, :otp => $otp_session_id},:api_key => @ap_key, :current_app_id => "test_app_id"}),nil,@headers
            user_json_hash = JSON.parse(response.body)
            
            expect(user_json_hash.keys).to match_array(["nothing"])
        end
        
        ##then to short poll with the intent token
        it " -- short polls for verification status, this time with an intent and an intent token, and verified as true"  do    
            @last_user_created = User.order_by(:confirmation_sent_at => 'desc').first
           get otp_verification_result_url({:resource => "users",:user => {:additional_login_param => @last_user_created.additional_login_param, :otp => $otp_session_id},:api_key => @ap_key, :current_app_id => "test_app_id", :intent => "reset_password"}),nil,@headers
            user_json_hash = JSON.parse(response.body)
            ##here check to see if a reset password email was sent.
            message = ActionMailer::Base.deliveries[-1].to_s
            rpt_index = message.index("reset_password_token")+"reset_password_token".length+1
            reset_password_token = message[rpt_index...message.index("\"", rpt_index)]
            expect(reset_password_token).not_to be(nil)
            expect(user_json_hash["verified"]).to eq(true)
           
        end

    end

    ##to do today
    context " -- forgot password flow without confirmed email. -- " do 

        ##so basically we have to call send sms otp with an intent.
        ##suppose we call it without an intent, then what happens?
        ##when we call the subsequent call, then ?
        before(:all) do 
            $otp_session_id = nil
            User.delete_all
        end

        after(:all) do 
            $otp_session_id = nil
           
        end

        it " -- on creating unconfirmed user with a mobile number, it sends otp -- " do 
            
            post user_registration_path, {user: attributes_for(:user_mobile),:api_key => @ap_key, :current_app_id => "test_app_id"}.to_json, @headers
            @user_created = assigns(:user)
            @cl = assigns(:client)
            user_json_hash = JSON.parse(response.body)
            expect(user_json_hash.keys).to match_array(["nothing"])
        
        end

        it " -- accepts otp at the verify otp endpoint -- " do 

            @last_user_created = User.order_by(:confirmation_sent_at => 'desc').first
            $otp_session_id = $redis.hget(@last_user_created.id.to_s + "_two_factor_sms_otp","otp_session_id")
            
            get verify_otp_url({:resource => "users",:user => {:additional_login_param => @last_user_created.additional_login_param, :otp => $otp_session_id},:api_key => @ap_key, :current_app_id => "test_app_id"}),nil,@headers
            user_json_hash = JSON.parse(response.body)
            
            expect(user_json_hash.keys).to match_array(["nothing"])
        end

        it " -- short polls for verification status, returns verified true"  do    
            @last_user_created = User.order_by(:confirmation_sent_at => 'desc').first
            
           
            get otp_verification_result_url({:resource => "users",:user => {:additional_login_param => @last_user_created.additional_login_param, :otp => $otp_session_id},:api_key => @ap_key, :current_app_id => "test_app_id"}),nil,@headers
            user_json_hash = JSON.parse(response.body)
            
            expect(user_json_hash["verified"]).to eq(true)
            expect(user_json_hash["resource"]).not_to include("authentication_token","es")
        end


        it " -- resends sms otp this time with an intent of reset password, " do 

            @last_user_created = User.order_by(:confirmation_sent_at => 'desc').first
           
            
            get send_sms_otp_url({:resource => "users",:user => {:additional_login_param => @last_user_created.additional_login_param},:api_key => @ap_key, :current_app_id => "test_app_id", :intent => "reset_password"}),nil,@headers
            
            user_json_hash = JSON.parse(response.body)
            
        end

        ##now it has to go to verify endpoint again.
        it " -- REVERIFIES OTP at the  verify otp endpoint -- " do 

            @last_user_created = User.order_by(:confirmation_sent_at => 'desc').first
            $otp_session_id = $redis.hget(@last_user_created.id.to_s + "_two_factor_sms_otp","otp_session_id")
            
            get verify_otp_url({:resource => "users",:user => {:additional_login_param => @last_user_created.additional_login_param, :otp => $otp_session_id},:api_key => @ap_key, :current_app_id => "test_app_id"}),nil,@headers
            user_json_hash = JSON.parse(response.body)
            
            expect(user_json_hash.keys).to match_array(["nothing"])
        end
        
        ##then to short poll with the intent token
        it " -- short polls for verification status, this time with an intent ,returns the reset password url, and verified as true"  do    
            @last_user_created = User.order_by(:confirmation_sent_at => 'desc').first
           get otp_verification_result_url({:resource => "users",:user => {:additional_login_param => @last_user_created.additional_login_param, :otp => $otp_session_id},:api_key => @ap_key, :current_app_id => "test_app_id", :intent => "reset_password"}),nil,@headers
            user_json_hash = JSON.parse(response.body)
            ##here check to see if a reset password email was sent.
            expect(user_json_hash["verified"]).to eq(false)
           
        end



    end

    ##to do today
    context  " -- unlock account flow -- " do 
        ##same flow as above but with unlock intent being passed around.
        ##so basically we have to call send sms otp with an intent.
        ##suppose we call it without an intent, then what happens?
        ##when we call the subsequent call, then ?
        before(:all) do 
            $otp_session_id = nil
            User.delete_all
        end

        after(:all) do 
            $otp_session_id = nil
            
        end

        it " -- on creating unconfirmed user with a mobile number, it sends otp -- " do 
            
            post user_registration_path, {user: attributes_for(:user_mobile),:api_key => @ap_key, :current_app_id => "test_app_id"}.to_json, @headers
            @user_created = assigns(:user)
            @cl = assigns(:client)
            user_json_hash = JSON.parse(response.body)
            expect(user_json_hash.keys).to match_array(["nothing"])
        
        end

        it " -- accepts otp at the verify otp endpoint -- " do 

            @last_user_created = User.order_by(:confirmation_sent_at => 'desc').first
            $otp_session_id = $redis.hget(@last_user_created.id.to_s + "_two_factor_sms_otp","otp_session_id")
            
            get verify_otp_url({:resource => "users",:user => {:additional_login_param => @last_user_created.additional_login_param, :otp => $otp_session_id},:api_key => @ap_key, :current_app_id => "test_app_id"}),nil,@headers
            user_json_hash = JSON.parse(response.body)
            
            expect(user_json_hash.keys).to match_array(["nothing"])
        end

        it " -- short polls for verification status, returns verified true"  do    
            @last_user_created = User.order_by(:confirmation_sent_at => 'desc').first
            
           
            get otp_verification_result_url({:resource => "users",:user => {:additional_login_param => @last_user_created.additional_login_param, :otp => $otp_session_id},:api_key => @ap_key, :current_app_id => "test_app_id"}),nil,@headers
            user_json_hash = JSON.parse(response.body)
            
            expect(user_json_hash["verified"]).to eq(true)
            expect(user_json_hash["resource"]).not_to include("authentication_token","es")
        end

        ##we then manually confirm the user.
        it " -- updates the user with a new email address " do 
            @last_user_created = User.order_by(:confirmation_sent_at => 'desc').first
                   
            a = {:id => @last_user_created.id.to_s, :user => {:email => "rihanna@gmail.com", :current_password => 'password'}, api_key: @ap_key, :current_app_id => "test_app_id"}
                   
            put user_registration_path, a.to_json,@headers.merge({"X-User-Token" => @last_user_created.authentication_token, "X-User-Es" => @last_user_created.client_authentication["test_app_id"], "X-User-Aid" => "test_app_id"})
            @user_updated = assigns(:user)
            ##manually confirm the email.
            @last_user_created = User.find(@last_user_created.id)
            @last_user_created.confirm!
            @last_user_created.save            

            expect(@last_user_created.email).to eq("rihanna@gmail.com")
           # expect(@last_user_created.errors).to be_empty
            expect(response.code).to eq("200")
        end

        it " -- resends sms otp this time with an intent of reset password,  " do 

            @last_user_created = User.order_by(:confirmation_sent_at => 'desc').first
           
            
            get send_sms_otp_url({:resource => "users",:user => {:additional_login_param => @last_user_created.additional_login_param},:api_key => @ap_key, :current_app_id => "test_app_id", :intent => "unlock_account"}),nil,@headers
            
            user_json_hash = JSON.parse(response.body)
            
            
        end

        ##now it has to go to verify endpoint again.
        it " -- REVERIFIES OTP at the  verify otp endpoint -- " do 

            @last_user_created = User.order_by(:confirmation_sent_at => 'desc').first
            $otp_session_id = $redis.hget(@last_user_created.id.to_s + "_two_factor_sms_otp","otp_session_id")
            
            get verify_otp_url({:resource => "users",:user => {:additional_login_param => @last_user_created.additional_login_param, :otp => $otp_session_id},:api_key => @ap_key, :current_app_id => "test_app_id"}),nil,@headers
            user_json_hash = JSON.parse(response.body)
            


            expect(user_json_hash.keys).to match_array(["nothing"])
        end
        
        ##then to short poll with the intent token
        it " -- short polls for verification status, this time with an intent and an intent token, returns verified as true", :nw => true  do    
            @last_user_created = User.order_by(:confirmation_sent_at => 'desc').first

            

            

            get otp_verification_result_url({:resource => "users",:user => {:additional_login_param => @last_user_created.additional_login_param, :otp => $otp_session_id},:api_key => @ap_key, :current_app_id => "test_app_id", :intent => "unlock_account"}),nil,@headers
            user_json_hash = JSON.parse(response.body)
            
           
            expect(user_json_hash["verified"]).to eq(true)
            expect(user_json_hash["resource"]).not_to include("authentication_token","es")
        end
    end


  end


end
