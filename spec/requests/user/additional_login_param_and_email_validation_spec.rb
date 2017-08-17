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
        Auth.configuration.stub_otp_api_calls = true
    end

    context " -- on creating account -- " do 

    	it "creating an account with email and additional login param produces a validation error." do 
    		usr_attrs = attributes_for(:user)
    		usr_attrs[:additional_login_param] = "9822028511"
    		post user_registration_path, {user: usr_attrs,:api_key => @ap_key, :current_app_id => "test_app_id"}.to_json, @headers
    		expect(assigns(:user).errors).not_to be_empty
    	end

    	

        context " -- flow test --- " do 
            
            context " --- create and confirm an account with a mobile number, then try to delete the mobile -- should give a validation error -- " do 

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

                    it " -- short polls for verification status, returns auth_token, es"  do    
                        @last_user_created = User.order_by(:confirmation_sent_at => 'desc').first
                        
                       
                        get otp_verification_result_url({:resource => "users",:user => {:_id => @last_user_created.id.to_s, :otp => $otp_session_id},:api_key => @ap_key, :current_app_id => "test_app_id"}),nil,@headers
                        user_json_hash = JSON.parse(response.body)
                       
                        expect(user_json_hash["verified"]).to eq(true)
                    expect(user_json_hash["resource"]).not_to include("authentication_token","es")
                    end

                    it " -- has errors if we try to delete the mobile now -- " do 

                        @last_user_created = User.order_by(:confirmation_sent_at => 'desc').first
                       

                        a = {:id => @last_user_created.id, :user => {:additional_login_param => "", :current_password => 'password'}, api_key: @ap_key, :current_app_id => "test_app_id"}

                        put user_registration_path, a.to_json,@headers.merge({"X-User-Token" => @last_user_created.authentication_token, "X-User-Es" => @last_user_created.client_authentication["test_app_id"], "X-User-Aid" => "test_app_id"})
                        @user_updated = assigns(:user)
                        expect(@user_updated.errors).not_to be_empty
                        
                    end

            end

            context " --- create and confirm an account with a mobile number,add an unconfirmed email,try to change the mobile -> should fail ---", :problem => true do 
                
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

                    it " -- short polls for verification status, returns auth_token, es"  do    
                        @last_user_created = User.order_by(:confirmation_sent_at => 'desc').first
                        
                       
                        get otp_verification_result_url({:resource => "users",:user => {:_id => @last_user_created.id.to_s, :otp => $otp_session_id},:api_key => @ap_key, :current_app_id => "test_app_id"}),nil,@headers
                        user_json_hash = JSON.parse(response.body)
                       
                        expect(user_json_hash["verified"]).to eq(true)
                    expect(user_json_hash["resource"]).not_to include("authentication_token","es")
                    end


                    it "-- update with a valid email. -- " do 
                        @last_user_created = User.order_by(:confirmation_sent_at => 'desc').first
                   
                        a = {:id => @last_user_created.id.to_s, :user => {:email => "rihanna@gmail.com", :current_password => 'password'}, api_key: @ap_key, :current_app_id => "test_app_id"}
                               
                        put user_registration_path, a.to_json,@headers.merge({"X-User-Token" => @last_user_created.authentication_token, "X-User-Es" => @last_user_created.client_authentication["test_app_id"], "X-User-Aid" => "test_app_id"})
                        @user_updated = assigns(:user)
                        expect(@user_updated.unconfirmed_email).to eq("rihanna@gmail.com")
                        expect(@user_updated.errors).to be_empty
                        expect(response.code).to eq("200")


                    end

                    it " -- has errors if we try to update the mobile now -- " do 

                        @last_user_created = User.order_by(:confirmation_sent_at => 'desc').first
                       

                        a = {:id => @last_user_created.id, :user => {:additional_login_param => "9822028511", :current_password => 'password'}, api_key: @ap_key, :current_app_id => "test_app_id"}

                        put user_registration_path, a.to_json,@headers.merge({"X-User-Token" => @last_user_created.authentication_token, "X-User-Es" => @last_user_created.client_authentication["test_app_id"], "X-User-Aid" => "test_app_id"})
                        @user_updated = assigns(:user)
                        expect(@user_updated.errors).not_to be_empty
                        
                    end
            end

            

            ##create an confirm an account with an email address
            ##add an unconfirmed mobile.
            ##try to change the email -> should fail
            ##try to change the mobile -> should fail.



            ##create an account with email
            ##then confirm
            ##should return auth_token and es
            ##now add mobile unconfirmed
            ##should return auth_token and es -> but auth_token should be different from earlier one.
            context " -- regeneration and return of auth_token and es even when unconfirmed additional_login_param added ", :problem => true do 
                

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

                it "-- creates confirmed email account " do 

                    post user_registration_path, {user: attributes_for(:user_confirmed),:api_key => @ap_key, :current_app_id => "test_app_id"}.to_json, @headers
                    @user_created = assigns(:user)
                    @cl = assigns(:client)
                    user_json_hash = JSON.parse(response.body)
                    
                   
                    expect(user_json_hash.keys).to match_array(["authentication_token","es"])

                end

                it " -- updates with a mobile number " do 
                    @last_user_created = User.order_by(:confirmation_sent_at => 'desc').first
                    auth_token = @last_user_created.authentication_token
                    es = @last_user_created.client_authentication["test_app_id"]
                    
                    a = {:id => @last_user_created.id.to_s, :user => {:additional_login_param => "9822028511", :current_password => 'password'}, api_key: @ap_key, :current_app_id => "test_app_id"}

                    put user_registration_path, a.to_json,@headers.merge({"X-User-Token" => @last_user_created.authentication_token, "X-User-Es" => @last_user_created.client_authentication["test_app_id"], "X-User-Aid" => "test_app_id"})
                    @user_updated = assigns(:user)
                    expect(response.code.to_s).to eq("200")
                    user_json_hash = JSON.parse(response.body)
                    expect(user_json_hash.keys).to match_array(["authentication_token","es"])
                    expect(@user_updated.authentication_token).not_to eq(auth_token)
                    expect(@user_updated.client_authentication["test_app_id"]).to eq(es)
                end

            end

            context " -- regeneration and return of auth_token and es even when unconfirmed email is added " do 

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

                    it " -- short polls for verification status, returns auth_token, es"  do    
                        @last_user_created = User.order_by(:confirmation_sent_at => 'desc').first
                        
                       
                        get otp_verification_result_url({:resource => "users",:user => {:_id => @last_user_created.id.to_s, :otp => $otp_session_id},:api_key => @ap_key, :current_app_id => "test_app_id"}),nil,@headers
                        user_json_hash = JSON.parse(response.body)
                       
                       expect(user_json_hash["verified"]).to eq(true)
                         expect(user_json_hash["resource"]).not_to include("authentication_token","es")
                    end


                it " -- does not return auth_token or es in case of any validation errors " do 

                    @last_user_created = User.order_by(:confirmation_sent_at => 'desc').first
                    auth_token = @last_user_created.authentication_token
                   
                    es = @last_user_created.client_authentication["test_app_id"]
                    ##here the current password is intentionally not sent to simulate a situation where there will be some validation errors.
                    a = {:id => @last_user_created.id.to_s, :user => {:email => "doggon@gmail.com"}, api_key: @ap_key, :current_app_id => "test_app_id"}

                    put user_registration_path, a.to_json,@headers.merge({"X-User-Token" => @last_user_created.authentication_token, "X-User-Es" => @last_user_created.client_authentication["test_app_id"], "X-User-Aid" => "test_app_id"})
                    @user_updated = assigns(:user)
                    expect(response.code.to_s).to eq("200")
                    user_json_hash = JSON.parse(response.body)
                    expect(user_json_hash).not_to include("authentication_token","es")
                end

                it " -- returns auth token and es, after adding an email account, and even before confirmation " do 

                    @last_user_created = User.order_by(:confirmation_sent_at => 'desc').first
                    auth_token = @last_user_created.authentication_token
                   
                    es = @last_user_created.client_authentication["test_app_id"]
                    
                    a = {:id => @last_user_created.id.to_s, :user => {:email => "doggon@gmail.com", :current_password => "password"}, api_key: @ap_key, :current_app_id => "test_app_id"}

                    put user_registration_path, a.to_json,@headers.merge({"X-User-Token" => @last_user_created.authentication_token, "X-User-Es" => @last_user_created.client_authentication["test_app_id"], "X-User-Aid" => "test_app_id"})
                    @user_updated = assigns(:user)
                    expect(response.code.to_s).to eq("200")
                    user_json_hash = JSON.parse(response.body)

                    expect(user_json_hash.keys).to match_array(["authentication_token","es"])
                    expect(@user_updated.authentication_token).not_to eq(auth_token)
                    expect(@user_updated.client_authentication["test_app_id"]).to eq(es)

                end

            end




        end

    end

  end


end
