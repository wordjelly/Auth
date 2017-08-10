##THESE TESTS MUST BE RUN IN THE SEQUENCE DEFINED BELOW, i.e AS THEY APPEAR IN THE TEST FILE.
require "rails_helper"

RSpec.describe "OTP flow requests", :otp => true, :type => :request do
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
        @headers = { "CONTENT_TYPE" => "application/json" , "ACCEPT" => "application/json", "X-User-Token" => @u.authentication_token, "X-User-Es" => @u.client_authentication["test_app_id"], "X-User-Aid" => "test_app_id"}
        @otp = 1234
        
    end

=begin
    context " -- basic otp flow --" do

        it " -- on creating unconfirmed user with a mobile number, it sends otp -- " do 
        	post user_registration_path, {user: attributes_for(:user_mobile),:api_key => @ap_key, :current_app_id => "test_app_id"}.to_json, @headers
            @user_created = assigns(:user)
            @cl = assigns(:client)
            user_json_hash = JSON.parse(response.body)
            expect(user_json_hash.keys).to match_array(["nothing"])
        end

        it " -- accepts otp at the verify otp endpoint -- " do 
        	user_attrs = attributes_for(:user_mobile)
        	@last_user_created = User.order_by(:created_at => 'desc').first
    		get verify_otp_url({:resource => "users",:user => {:additional_login_param => @last_user_created.additional_login_param, :otp => @otp}}),nil,@headers
    		user_json_hash = JSON.parse(response.body)
            expect(user_json_hash.keys).to match_array(["nothing"])
        end

        it " -- short polls for verification status, returns auth_token, es"  do 	
        	@last_user_created = User.order_by(:created_at => 'desc').first
        	get otp_verification_result_url({:resource => "users",:user => {:_id => @last_user_created.id.to_s, :otp => @otp},:api_key => @ap_key, :current_app_id => "test_app_id"}),nil,@headers
        	user_json_hash = JSON.parse(response.body)
        	puts user_json_hash.to_s
            expect(user_json_hash["resource"].keys).to match_array(["authentication_token","es"])
        end

    end
=end

    ##to do today
    context " -- resend otp flow -- " do 

        it " -- on creating unconfirmed user with a mobile number, it sends otp -- " do 
            
            post user_registration_path, {user: attributes_for(:user_mobile),:api_key => @ap_key, :current_app_id => "test_app_id"}.to_json, @headers
            @user_created = assigns(:user)
            @cl = assigns(:client)
            user_json_hash = JSON.parse(response.body)
            expect(user_json_hash.keys).to match_array(["nothing"])
        end

        it "-- resends otp on hitting the resend endpoint " do 
            @last_user_created = User.order_by(:confirmation_sent_at => 'desc').first
            
            get resend_sms_otp_url({:resource => "users",:user => {:additional_login_param => @last_user_created.additional_login_param},:api_key => @ap_key, :current_app_id => "test_app_id"}),nil,@headers
            user_json_hash = JSON.parse(response.body)
           
            expect(user_json_hash.keys).to match_array(["nothing"])
        end

        it " -- accepts otp at the verify otp endpoint -- " do 
            @last_user_created = User.order_by(:confirmation_sent_at => 'desc').first
           
            get verify_otp_url({:resource => "users",:user => {:additional_login_param => @last_user_created.additional_login_param, :otp => @otp},:api_key => @ap_key, :current_app_id => "test_app_id"}),nil,@headers
            user_json_hash = JSON.parse(response.body)
            
            expect(user_json_hash.keys).to match_array(["nothing"])
        end

        it " -- short polls for verification status, returns auth_token, es"  do    
            @last_user_created = User.order_by(:confirmation_sent_at => 'desc').first
            get otp_verification_result_url({:resource => "users",:user => {:_id => @last_user_created.id.to_s, :otp => @otp},:api_key => @ap_key, :current_app_id => "test_app_id"}),nil,@headers
            user_json_hash = JSON.parse(response.body)
            
            expect(user_json_hash["resource"].keys).to match_array(["authentication_token","es"])
        end

        it " -- does not return es or auth_token if there are errors from the short polling endpoint " do 
            @last_user_created = User.order_by(:confirmation_sent_at => 'desc').first
            $redis.hset(@last_user_created.id.to_s + "_two_factor_sms_otp","error","some bloody error")
            get otp_verification_result_url({:resource => "users",:user => {:_id => @last_user_created.id.to_s, :otp => @otp},:api_key => @ap_key, :current_app_id => "test_app_id"}),nil,@headers
            user_json_hash = JSON.parse(response.body)
            expect(user_json_hash["resource"].keys).not_to include("authentication_token","es") 

        end

        it " -- does not process short polling endpoint without api_key and current_app_id " do 
            @last_user_created = User.order_by(:confirmation_sent_at => 'desc').first
            
            get otp_verification_result_url({:resource => "users",:user => {:_id => @last_user_created.id.to_s, :otp => @otp},:api_key => @ap_key}),nil,@headers
            
            
            expect(response.body).to be_empty

        end

    end

    ##to do today
    context " -- invalid otp flow -- " do 

        ##add auth configuration changes.
        ##and simulate wrong otp, etc.

    
    end

    ##to do today
    context " -- forgot password flow -- " do 


    end

    context  " -- unlock account flow -- " do 


    end

    context " -- nil values --- " do 
        

    end

  end


end
