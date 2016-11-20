require "rails_helper"

RSpec.describe "session request spec", :type => :request do 

	before(:example) do 

		ActionController::Base.allow_forgery_protection = true
        Admin.delete_all
        Auth::Client.delete_all
        @u = Admin.new(attributes_for(:admin_confirmed))
        @u.save
        @c = Auth::Client.new(:resource_id => @u.id, :api_key => "test")
        @c.redirect_urls = ["http://www.google.com"]
        @c.versioned_create
        @ap_key = @c.api_key
        @headers = { "CONTENT_TYPE" => "application/json" , "ACCEPT" => "application/json", "X-Admin-Token" => @u.authentication_token, "X-Admin-Es" => @u.es}

	end

	after(:example) do 
		session.delete(:client)
		session.delete(:redirect_url)
	end

	context " -- web app requests" do 

		before(:example) do 

			ActionController::Base.allow_forgery_protection = false

		end

		context " -- valid api key with redirect url" do 

			it " -- GET Request,should set the session variables " do 

				get new_admin_session_path,{redirect_url: "http://www.google.com", api_key: @ap_key}
				expect(session[:client]).not_to be_nil
				expect(session[:redirect_url]).not_to be_nil
				

			end

			it " -- CREATE request, should redirect with the auth_token and es " do 
				
				post admin_session_path,{redirect_url: "http://www.google.com", api_key: @ap_key, admin: {email: @u.email, password: "password"}}
				@admin = assigns(:admin)
				expect(response.code).to eq("302")
				expect(response).to redirect_to("http://www.google.com?authentication_token=#{@u.authentication_token}&es=#{@u.es}")
				expect(@admin).not_to be_nil
       			expect(@admin.errors.full_messages).to be_empty 

			end

			it " -- DESTROY Request, should not redirect. " do 
				
				sign_in_as_a_valid_admin
				delete "/authenticate/admins/sign_out",{:id => @admin.id, redirect_url: "http://www.google.com", api_key: @ap_key}
				expect(response.code).to eq("302")
				expect(response).to redirect_to(root_path)
				expect(@admin.errors.full_messages).to be_empty         		
			end

		end


	end

	

end
