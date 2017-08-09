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
        	a = {}
        	a[:user] = {:additional_login_param => "123456789"}
    		get verify_otp_url({:resource => "users",:user => {:additional_login_param => "123456789", :otp => @otp}}),nil,@headers
    		user_json_hash = JSON.parse(response.body)
            expect(user_json_hash.keys).to match_array(["nothing"])
        end

        it " -- short polls for verification status, returns auth_token, es"  do 	
        	u = User.where(:additional_login_param => "123456789").first
        	get otp_verification_result_url({:resource => "users",:user => {:_id => u.id.to_s, :otp => @otp},:api_key => @ap_key, :current_app_id => "test_app_id"}),nil,@headers
        	user_json_hash = JSON.parse(response.body)
        	puts user_json_hash.to_s
            expect(user_json_hash["resource"].keys).to match_array(["authentication_token","es"])
        end

    end

    context " -- resend otp flow -- " do 


    end


    context " -- invalid otp flow -- " do 


    end

    context " -- forgot password flow -- " do 


    end

    context  " -- unlock account flow -- " do 


    end

    context " -- no otp resource on path --- " do 

    end

    context " -- nil values --- " do 
        

    end

  end


end
