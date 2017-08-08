##this checks the validation rules set on both the additional_login_param and email.
require "rails_helper"

RSpec.describe "Additional login param and email flow requests", :alp_email => true, :type => :request do
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
        @otp = 1234
        
    end

    context " -- on creating account -- " do 

    	it "creating an account with email and additional login param produces a validation error." do 
    		usr_attrs = attributes_for(:user)
    		usr_attrs[:additional_login_param] = "9822028511"
    		post user_registration_path, {user: usr_attrs,:api_key => @ap_key, :current_app_id => "test_app_id"}.to_json, @headers
    		expect(assigns(:user).errors).not_to be_empty
    	end

    	

        context " -- flow test --- " do 
            context " --- ##create and confirm an account with a mobile number
            ##then try to delete the number
            ##add an unconfirmed email.
            ##try to change the mobile -> should fail
            ##try to delete the mobile -> should fail. ---" do 
                
                it " -- on creating unconfirmed user with a mobile number, it sends otp -- " do 
                    post user_registration_path, {user: attributes_for(:user_mobile),:api_key => @ap_key, :current_app_id => "test_app_id"}.to_json, @headers
                    @user_created = assigns(:user)
                    @cl = assigns(:client)
                    user_json_hash = JSON.parse(response.body)
                    expect(user_json_hash.keys).to match_array(["nothing"])
                end

                it " -- accepts otp at the verify otp endpoint -- " do 
                    #user_attrs = attributes_for(:user_mobile)
                    #a = {}
                    #a[:user] = {:additional_login_param => "123456789"}
                    get verify_otp_url({:resource => "users",:user => {:additional_login_param => "123456789", :otp => @otp}}),nil,@headers
                    user_json_hash = JSON.parse(response.body)
                    expect(user_json_hash.keys).to match_array(["nothing"])
                end

                it " -- short polls for verification status, returns auth_token, es"  do    
                    u = User.where(:additional_login_param => "123456789").first
                    get otp_verification_result_url({:resource => "users",:user => {:_id => u.id.to_s, :otp => @otp},:api_key => @ap_key, :current_app_id => "test_app_id"}),nil,@headers
                    user_json_hash = JSON.parse(response.body)
                    
                    expect(user_json_hash["resource"].keys).to match_array(["authentication_token","es"])
                end

                it "-- update with a valid email. -- " do 
                    u = User.where(:additional_login_param => "123456789").first
                    a = {:id => u.id.to_s, :user => {:email => "rihanna@gmail.com", :current_password => 'password'}, api_key: @ap_key, :current_app_id => "test_app_id"}
                               
                    put user_registration_path, a.to_json,@headers.merge({"X-User-Token" => u.authentication_token, "X-User-Es" => u.client_authentication["test_app_id"], "X-User-Aid" => "test_app_id"})
                    @user_updated = assigns(:user)


                    expect(@user_updated.unconfirmed_email).to eq("rihanna@gmail.com")
                    expect(@user_updated.errors).to be_empty
                    expect(response.code).to eq("204")


                end

                it " -- has errors if we try to update the mobile now -- " do 

                    u = User.where(:additional_login_param => "123456789").first
                    
                   

                    a = {:id => u.id, :user => {:additional_login_param => "13123130u3094", :current_password => 'password'}, api_key: @ap_key, :current_app_id => "test_app_id"}

                    put user_registration_path, a.to_json,@headers.merge({"X-User-Token" => u.authentication_token, "X-User-Es" => u.client_authentication["test_app_id"], "X-User-Aid" => "test_app_id"})
                    @user_updated = assigns(:user)
                    expect(@user_updated.errors).not_to be_empty
                    expect(response.code).to eq("422")


                end

            end

            ##create an confirm an account with an email address
            ##add an unconfirmed mobile.
            ##try to change the email -> should fail
            ##try to change the mobile -> should fail.

            ##create an account with an unconfirmed mobile
            ##try to update that account
            ##should not work.

            ##create an account with an unconfirmed email
            ##try to change the email address -> it should fail.

            ##create an account with a mobile
            ##confirm it
            ##add an email, and simultaneously change the email -> should fail

            ##create an account with a email
            ##confirm it
            ##add a mobile, and simultaneously change the email -> should fail
        end

    end


=begin
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
=end

  end


end
