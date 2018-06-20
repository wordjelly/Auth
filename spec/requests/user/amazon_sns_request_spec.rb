require "rails_helper"

RSpec.describe "Registration requests", :amazon_endpoint => true,:authentication => true, :type => :request do
	before(:all) do 
	    Auth.configuration.recaptcha = true
	    User.delete_all
	    Auth::Client.delete_all
	    module Devise

	      	RegistrationsController.class_eval do

		        def sign_up_params
		          ##quick hack to make registrations controller accept confirmed_at, because without that there is no way to send in a confirmed admin directly while creating the admin.
		          params.require(:user).permit(
		            :email, :password, :password_confirmation,
		          )
		        end

	      	end

	    end
	end

	context " -- json requests -- " do 

		after(:example) do 
	      User.delete_all
	      Auth::Client.delete_all
	    end

	    before(:example) do 
	        ActionController::Base.allow_forgery_protection = true
	        User.delete_all
	        Auth::Client.delete_all
	        @u = User.new(attributes_for(:user_confirmed))
	        @u.versioned_create
	        @c = Auth::Client.new(:resource_id => @u.id, :api_key => "test", :app_ids => ["testappid"])
	        @c.redirect_urls = ["http://www.google.com"]
	        @c.versioned_create
	        @u.client_authentication["testappid"] = "testestoken"
	        @u.versioned_update
	        @ap_key = @c.api_key
	        
	        
	        ## second user.
	        @u2 = User.new(attributes_for(:user_confirmed))
	        @u2.versioned_create
	        @u2.client_authentication["testappid"] = "testestoken1"
	        @u2.versioned_update

	        @headers = { "CONTENT_TYPE" => "application/json" , "ACCEPT" => "application/json","X-User-Token" => @u2.authentication_token, "X-User-Es" => "testestoken1", "X-User-Aid" => "testappid"}

	    end	

		it " -- adds android endpoint to user -- " do 

		    a = {:id => @u2.id.to_s, :user => {:android_token => "xyz"}, api_key: @ap_key, :current_app_id => "testappid", :resource => "users"}
		    
		    put credential_exists_profiles_path, a.to_json, @headers

		    ## get this user
		    ## assert that it has an endpoint.
		    user = User.find(@u2.id.to_s)
		    expect(user.android_endpoint).not_to be_nil

		end

		it " -- creates android endpoint only from json request -- " do 



		end

	end

end
