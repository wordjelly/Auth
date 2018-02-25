##this checks the validation rules set on both the additional_login_param and email.
require "rails_helper"

RSpec.describe "Additional login param and email flow requests", :alp_email => true, :authentication => true, :type => :request do
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
        @c = Auth::Client.new(:resource_id => @u.id, :api_key => "test", :app_ids => ["testappid"])
        @c.redirect_urls = ["http://www.google.com"]
        @c.versioned_create
        @u.client_authentication["testappid"] = "test_es_token"
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
    		post user_registration_path, {user: usr_attrs,:api_key => @ap_key, :current_app_id => "testappid"}.to_json, @headers
    		expect(assigns(:user).errors).not_to be_empty
    	end

        context " -- mobile validations -- ", :mobile_validations => true do 

        	context " -- additional login param validations " do 

                before(:all) do 
                        ActionController::Base.allow_forgery_protection = true
                        User.delete_all
                        Auth::Client.delete_all
                        @u = User.new(attributes_for(:user_confirmed))
                        @u.save
                        @c = Auth::Client.new(:resource_id => @u.id, :api_key => "test", :app_ids => ["testappid"])
                        @c.redirect_urls = ["http://www.google.com"]
                        @c.versioned_create
                        @u.client_authentication["testappid"] = "test_es_token"
                        @u.save
                        @ap_key = @c.api_key
                        @headers = { "CONTENT_TYPE" => "application/json" , "ACCEPT" => "application/json"}
                        @otp = 1234
                        Auth.configuration.stub_otp_api_calls = true
                end

                it " --- gives a validation error if additional login param is not a valid mobile on CREATE -- " do 
                    post user_registration_path, {user: attributes_for(:user_mobile_invalid),:api_key => @ap_key, :current_app_id => "testappid"}.to_json, @headers
                    @user_created = assigns(:user)
                    @cl = assigns(:client)
                    user_json_hash = JSON.parse(response.body)
                    expect(user_json_hash.keys).to match_array(["errors","nothing"])
                end


            end

            context " - does not update with invalid mobile -- " do 

                    before(:all) do 
                        ActionController::Base.allow_forgery_protection = true
                        User.delete_all
                        Auth::Client.delete_all
                        @u = User.new(attributes_for(:user_confirmed))
                        @u.save
                        @c = Auth::Client.new(:resource_id => @u.id, :api_key => "test", :app_ids => ["testappid"])
                        @c.redirect_urls = ["http://www.google.com"]
                        @c.versioned_create
                        @u.client_authentication["testappid"] = "test_es_token"
                        @u.save
                        @ap_key = @c.api_key
                        @headers = { "CONTENT_TYPE" => "application/json" , "ACCEPT" => "application/json"}
                        
                        Auth.configuration.stub_otp_api_calls = true
                    end

                    

                    it " -- has errors if we try to update with an invalid mobile number now -- ", :ee => true do 

                        
                        last_user_created = User.new(attributes_for(:user_mobile_confirmed))
                        last_user_created.m_client = @c
                        last_user_created.m_client.current_app_id = "testappid"
                        last_user_created.save
                        last_user_created.additional_login_param_status = 2
                        last_user_created.save
                      


                        a = {:id => last_user_created.id, :user => {:additional_login_param => Faker::Name.name, :current_password => 'password'}, api_key: @ap_key, :current_app_id => "testappid"}

                        put user_registration_path, a.to_json,@headers.merge({"X-User-Token" => last_user_created.authentication_token, "X-User-Es" => last_user_created.client_authentication["testappid"], "X-User-Aid" => "testappid"})
                        
                        @user_updated = assigns(:user)
                        expect(@user_updated.errors).not_to be_empty
                        user_json_hash = JSON.parse(response.body)
                        expect(user_json_hash.keys).to match_array(["nothing","errors"])
                    end


            end
            
            ##with redirect the targets are as follows:
            ## => should redirect with mobile flow
            ## => should be able to switch off redirect functionality

            context " -- validation flow - create account with confirmed email, then add invalid mobile - should throw error " do 

                     before(:all) do 

                        ActionController::Base.allow_forgery_protection = true
                        User.delete_all
                        Auth::Client.delete_all
                        @u = User.new(attributes_for(:user_confirmed))
                        @u.save
                        @c = Auth::Client.new(:resource_id => @u.id, :api_key => "test", :app_ids => ["testappid"])
                        @c.redirect_urls = ["http://www.google.com"]
                        @c.versioned_create
                        @u.client_authentication["testappid"] = "test_es_token"
                        @u.save
                        @ap_key = @c.api_key
                        @headers = { "CONTENT_TYPE" => "application/json" , "ACCEPT" => "application/json"}
                        @otp = 1234
                        Auth.configuration.stub_otp_api_calls = true
                    end


                    it "-- creates confirmed email account " do 

                        post user_registration_path, {user: attributes_for(:user_confirmed),:api_key => @ap_key, :current_app_id => "testappid"}.to_json, @headers
                        @user_created = assigns(:user)
                        
                        @cl = assigns(:client)
                        
                        user_json_hash = JSON.parse(response.body)
                        
                       
                        expect(user_json_hash.keys).to match_array(["authentication_token","es"])

                    end

                    it " -- fails to update with invalid mobile number -- ", :exec => true do 



                         user = User.new(attributes_for(:user_confirmed))
                         
                         user.m_client = @c
                         user.m_client.current_app_id = "testappid"
                         expect(user.save).to be_truthy
                         user.confirm!
                        a = {:id => user.id, :user => {:additional_login_param => Faker::Name.name, :current_password => 'password'}, api_key: @ap_key, :current_app_id => "testappid"}

                        put user_registration_path, a.to_json,@headers.merge({"X-User-Token" => user.authentication_token, "X-User-Es" => user.client_authentication["testappid"], "X-User-Aid" => "testappid"})
                       
                       

                        @user_updated = assigns(:user)
                        expect(@user_updated.errors).not_to be_empty
                        user_json_hash = JSON.parse(response.body)
                        expect(user_json_hash.keys).to match_array(["nothing","errors"])

                    end


            end

        end

        context " -- flow test --- " do 
            
            context " --- create and confirm an account with a mobile number, then try to delete the mobile -- should give a validation error -- " do 

                before(:all) do 
                    ActionController::Base.allow_forgery_protection = true
                    User.delete_all
                    Auth::Client.delete_all
                    @u = User.new(attributes_for(:user_confirmed))
                    @u.save
                    @c = Auth::Client.new(:resource_id => @u.id, :api_key => "test", :app_ids => ["testappid"])
                    @c.redirect_urls = ["http://www.google.com"]
                    @c.versioned_create
                    @u.client_authentication["testappid"] = "test_es_token"
                    @u.save
                    @ap_key = @c.api_key
                    @headers = { "CONTENT_TYPE" => "application/json" , "ACCEPT" => "application/json"}
                    @otp = 1234
                    Auth.configuration.stub_otp_api_calls = true
                end

              

 

                it " -- has errors if we try to delete the mobile now -- " do 

                    last_user_created = User.new(attributes_for(:user_mobile_confirmed))
                    last_user_created.m_client = @c
                    last_user_created.m_client.current_app_id = "testappid"
                    last_user_created.save
                    last_user_created.additional_login_param_status = 2
                    last_user_created.save
                   

                    a = {:id => last_user_created.id, :user => {:additional_login_param => "", :current_password => 'password'}, api_key: @ap_key, :current_app_id => "testappid"}

                    put user_registration_path, a.to_json,@headers.merge({"X-User-Token" => last_user_created.authentication_token, "X-User-Es" => last_user_created.client_authentication["testappid"], "X-User-Aid" => "testappid"})
                    @user_updated = assigns(:user)
                    expect(@user_updated.errors).not_to be_empty
                    
                end

            end

            context " -- create an confirm a mobile number, try to change it, -- should fail, without a confirmed email " do 

                 before(:all) do 
                    ActionController::Base.allow_forgery_protection = true
                    User.delete_all
                    Auth::Client.delete_all
                    @u = User.new(attributes_for(:user_confirmed))
                    @u.save
                    @c = Auth::Client.new(:resource_id => @u.id, :api_key => "test", :app_ids => ["testappid"])
                    @c.redirect_urls = ["http://www.google.com"]
                    @c.versioned_create
                    @u.client_authentication["testappid"] = "test_es_token"
                    @u.save
                    @ap_key = @c.api_key
                    @headers = { "CONTENT_TYPE" => "application/json" , "ACCEPT" => "application/json"}
                    @otp = 1234
                    Auth.configuration.stub_otp_api_calls = true
                end 

               
                   

                    it " -- has errors if we try to update the mobile now -- " do 

                        last_user_created = User.new(attributes_for(:user_mobile_confirmed))
                        last_user_created.m_client = @c
                        last_user_created.m_client.current_app_id = "testappid"
                        last_user_created.save
                        last_user_created.additional_login_param_status = 2
                        last_user_created.save
                       

                        a = {:id => last_user_created.id, :user => {:additional_login_param => "9561137096", :current_password => 'password'}, api_key: @ap_key, :current_app_id => "testappid"}

                        put user_registration_path, a.to_json,@headers.merge({"X-User-Token" => last_user_created.authentication_token, "X-User-Es" => last_user_created.client_authentication["testappid"], "X-User-Aid" => "testappid"})
                        @user_updated = assigns(:user)
                        expect(@user_updated.errors).to be_empty
                        
                    end


            end

            
            context " --- create and confirm an account with a mobile number,add an unconfirmed email,try to change the mobile -> should fail ---" do 
                
                 before(:all) do 
                    ActionController::Base.allow_forgery_protection = true
                    User.delete_all
                    Auth::Client.delete_all
                    @u = User.new(attributes_for(:user_confirmed))
                    @u.save
                    @c = Auth::Client.new(:resource_id => @u.id, :api_key => "test", :app_ids => ["testappid"])
                    @c.redirect_urls = ["http://www.google.com"]
                    @c.versioned_create
                    @u.client_authentication["testappid"] = "test_es_token"
                    @u.save
                    @ap_key = @c.api_key
                    @headers = { "CONTENT_TYPE" => "application/json" , "ACCEPT" => "application/json"}
                    @otp = 1234
                    Auth.configuration.stub_otp_api_calls = true
                end




                    it "-- update with a valid email. -- " do 
                        last_user_created = User.new(attributes_for(:user_mobile_confirmed))
                        last_user_created.m_client = @c
                        last_user_created.m_client.current_app_id = "testappid"
                        last_user_created.save
                        last_user_created.additional_login_param_status = 2
                        last_user_created.save
                   
                        a = {:id => last_user_created.id.to_s, :user => {:email => "rihanna@gmail.com", :current_password => 'password'}, api_key: @ap_key, :current_app_id => "testappid"}
                               
                        put user_registration_path, a.to_json,@headers.merge({"X-User-Token" => last_user_created.authentication_token, "X-User-Es" => last_user_created.client_authentication["testappid"], "X-User-Aid" => "testappid"})
                        @user_updated = assigns(:user)
                        expect(@user_updated.unconfirmed_email).to eq("rihanna@gmail.com")
                        expect(@user_updated.errors).to be_empty
                        expect(response.code).to eq("200")


                    end

                    it " -- has errors if we try to update the mobile now -- " do 

                        last_user_created = User.new(attributes_for(:user_mobile_confirmed))
                        last_user_created.m_client = @c
                        last_user_created.m_client.current_app_id = "testappid"
                        last_user_created.save
                        last_user_created.additional_login_param_status = 2
                        last_user_created.email = "test_email@gmail.com"
                        last_user_created.save
                       

                        a = {:id => last_user_created.id, :user => {:additional_login_param => "9822028511", :current_password => 'password'}, api_key: @ap_key, :current_app_id => "testappid"}

                        put user_registration_path, a.to_json,@headers.merge({"X-User-Token" => last_user_created.authentication_token, "X-User-Es" => last_user_created.client_authentication["testappid"], "X-User-Aid" => "testappid"})

                        expect(response.code).not_to eq("204")

                        @user_updated = assigns(:user)
                        expect(@user_updated.errors).not_to be_empty
                        
                    end
            end

            

            ##create an confirm an account with an email address
            ##add an unconfirmed mobile.
            ##try to change the email -> should fail
            ##try to change the mobile -> should fail.
            context " -- create a confirmed email, then change the email , it should pass -- " do 


                before(:all) do 
                    ActionController::Base.allow_forgery_protection = true
                    User.delete_all
                    Auth::Client.delete_all
                    @u = User.new(attributes_for(:user_confirmed))
                    @u.save
                    @c = Auth::Client.new(:resource_id => @u.id, :api_key => "test", :app_ids => ["testappid"])
                    @c.redirect_urls = ["http://www.google.com"]
                    @c.versioned_create
                    @u.client_authentication["testappid"] = "test_es_token"
                    @u.save
                    @ap_key = @c.api_key
                    @headers = { "CONTENT_TYPE" => "application/json" , "ACCEPT" => "application/json"}
                    @otp = 1234
                    Auth.configuration.stub_otp_api_calls = true
                end


                it "-- creates confirmed email account " do 

                    post user_registration_path, {user: attributes_for(:user_confirmed),:api_key => @ap_key, :current_app_id => "testappid"}.to_json, @headers
                    @user_created = assigns(:user)
                    @cl = assigns(:client)
                    user_json_hash = JSON.parse(response.body)
                    
                   
                    expect(user_json_hash.keys).to match_array(["authentication_token","es"])

                end

                it "-- user with confirmed email and unconfirmed mobile, will not be updated with new email -- ", :rd => true do 

                    last_user_created = User.new(attributes_for(:user_confirmed))
                    last_user_created.m_client = @c
                    last_user_created.m_client.current_app_id = "testappid"
                    last_user_created.save
                    last_user_created.confirm!
                    last_user_created.additional_login_param = "9822028511"
                    last_user_created.save
                    
                    a = {:id => last_user_created.id.to_s, :user => {:email => "jeronimo1122334@gmail.com", :current_password => 'password'}, api_key: @ap_key, :current_app_id => "testappid"}

                    put user_registration_path, a.to_json,@headers.merge({"X-User-Token" => last_user_created.authentication_token, "X-User-Es" => last_user_created.client_authentication["testappid"], "X-User-Aid" => "testappid"})

                    @user_updated = assigns(:user)
                    user_json_hash = JSON.parse(response.body)
                    puts user_json_hash.to_s
                    expect(user_json_hash.keys).to match_array(["errors","nothing"])
                    expect(response.code.to_s).to eq("200")
                    expect(@user_updated.errors).not_to  be_empty
                end

            end

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
                    @c = Auth::Client.new(:resource_id => @u.id, :api_key => "test", :app_ids => ["testappid"])
                    @c.redirect_urls = ["http://www.google.com"]
                    @c.versioned_create
                    @u.client_authentication["testappid"] = "test_es_token"
                    @u.save
                    @ap_key = @c.api_key
                    @headers = { "CONTENT_TYPE" => "application/json" , "ACCEPT" => "application/json"}
                    @otp = 1234
                    
                end

            

                it " -- updates with a mobile number ", :rx => true do 
                    
                    last_user_created = User.new(attributes_for(:user_confirmed))
                    last_user_created.m_client = @c
                    last_user_created.m_client.current_app_id = "testappid"
                    last_user_created.save
                    last_user_created.confirm!
                    #puts last_user_created.attributes.to_s
                    #puts "pending reconfirmation--------------------------"
                    #puts last_user_created.pending_reconfirmation?

                    auth_token = last_user_created.authentication_token
                    es = last_user_created.client_authentication["testappid"]
                    
                    a = {:id => last_user_created.id.to_s, :user => {:additional_login_param => "9822028511", :current_password => 'password'}, api_key: @ap_key, :current_app_id => "testappid"}

                    put user_registration_path, a.to_json,@headers.merge({"X-User-Token" => last_user_created.authentication_token, "X-User-Es" => last_user_created.client_authentication["testappid"], "X-User-Aid" => "testappid"})

                    
                    @user_updated = assigns(:user)
                    expect(response.code.to_s).to eq("200")
                    

                    user_json_hash = JSON.parse(response.body)
                    
                    puts user_json_hash.to_s

                    expect(user_json_hash.keys).to match_array(["authentication_token","es"])
                    expect(@user_updated.authentication_token).not_to eq(auth_token)
                    expect(@user_updated.client_authentication["testappid"]).to eq(es)
                end

            end

            context " -- regeneration and return of auth_token and es even when unconfirmed email is added " do 

                before(:all) do 

                    ActionController::Base.allow_forgery_protection = true
                    User.delete_all
                    Auth::Client.delete_all
                    @u = User.new(attributes_for(:user_confirmed))
                    @u.save
                    @c = Auth::Client.new(:resource_id => @u.id, :api_key => "test", :app_ids => ["testappid"])
                    @c.redirect_urls = ["http://www.google.com"]
                    @c.versioned_create
                    @u.client_authentication["testappid"] = "test_es_token"
                    @u.save
                    @ap_key = @c.api_key
                    @headers = { "CONTENT_TYPE" => "application/json" , "ACCEPT" => "application/json"}
                    @otp = 1234
                    
                end 

             
                it " -- does not return auth_token or es in case of any validation errors ", :rg => true do 

                    last_user_created = User.new(attributes_for(:user_mobile_confirmed))
                    last_user_created.m_client = @c
                    last_user_created.m_client.current_app_id = "testappid"
                    expect(last_user_created.save).to be_truthy
                    last_user_created.additional_login_param_status = 2
                    expect(last_user_created.save).to be_truthy
                   
                    
                    a = {:id => last_user_created.id.to_s, :user => {:email => "doggon@gmail.com"}, api_key: @ap_key, :current_app_id => "testappid"}

                    put user_registration_path, a.to_json,@headers.merge({"X-User-Token" => last_user_created.authentication_token, "X-User-Es" => last_user_created.client_authentication["testappid"], "X-User-Aid" => "testappid"})

                    @user_updated = assigns(:user)
                    
                    expect(response.code.to_s).to eq("200")
                    
                    user_json_hash = JSON.parse(response.body)
                    
                    expect(user_json_hash).not_to include("authentication_token","es")
                end

                it " -- returns auth token and es, after adding an email account, and even before confirmation ", :crest => true do 

                    last_user_created = User.new(attributes_for(:user_mobile_confirmed))
                    
                    last_user_created.m_client = @c
                    
                    last_user_created.m_client.current_app_id = "testappid"
                    
                    expect(last_user_created.save).to be_truthy
                    
                    last_user_created.additional_login_param_status = 2

                    last_user_created.save

                    auth_token = last_user_created.authentication_token

                    es = last_user_created.client_authentication["testappid"]
                    
                    a = {:id => last_user_created.id.to_s, :user => {:email => "doggon@gmail.com", :current_password => "password"}, api_key: @ap_key, :current_app_id => "testappid"}

                    put user_registration_path, a.to_json,@headers.merge({"X-User-Token" => last_user_created.authentication_token, "X-User-Es" => last_user_created.client_authentication["testappid"], "X-User-Aid" => "testappid"})
                    
                    @user_updated = assigns(:user)
                    
                    expect(response.code.to_s).to eq("200")
                    
                    user_json_hash = JSON.parse(response.body)

                    expect(user_json_hash.keys).to match_array(["authentication_token","es"])
                    
                    expect(@user_updated.authentication_token).not_to eq(auth_token)
                    
                    expect(@user_updated.client_authentication["testappid"]).to eq(es)

                end

            end

        end

    end

  end


end
