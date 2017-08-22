require "rails_helper"

=begin
in the following "web-app-context" tests and "json-request" tests, we sign in the same admin whose client we use for authentication.
basically we have created one admin in the before(:example) , and with it an asscoiated client is created.
now in all the tests, we sign in this admin only, using its own client. normally we could also sign in other admins using this client.
=end

RSpec.describe "session request spec",:admin_session => true, :type => :request do 

	

	context " -- web app requests" do 

		before(:example) do 

			ActionController::Base.allow_forgery_protection = false
	        Admin.delete_all
	        Auth::Client.delete_all
	        @u = Admin.new(attributes_for(:admin_confirmed))
	        @u.save
	        @c = Auth::Client.where(:resource_id => @u.id).first
	        @c.api_key = "test"
	        @c.redirect_urls = ["http://www.google.com"]
	        @c.app_ids << "test_app_id"
	        @c.versioned_update
	        @ap_key = @c.api_key
		end

		

		context " -- valid api key with redirect url" do 

			it " -- GET Request,should set the session variables " do 

				get new_admin_session_path,{redirect_url: "http://www.google.com", api_key: @ap_key, current_app_id: @c.app_ids[0]}
				expect(session[:client]).not_to be_nil
				expect(session[:redirect_url]).not_to be_nil
				
			end

			it " -- CREATE request, should redirect with the auth_token and es " do 
				
				
				post admin_session_path,{admin: {login: @u.email, password: "password"},redirect_url: "http://www.google.com", api_key: @ap_key, current_app_id: @c.app_ids[0]}
				admin = assigns(:admin)
				expect(response.code).to eq("302")
				expect(response).to redirect_to("http://www.google.com?authentication_token=#{admin.authentication_token}&es=#{admin.client_authentication[@c.app_ids[0]]}")
				expect(admin).not_to be_nil
       			expect(admin.errors.full_messages).to be_empty 

			end

			it " -- DESTROY Request, should not redirect. " do 
				
				sign_in_as_a_valid_and_confirmed_admin
				delete destroy_admin_session_path,{:id => @admin.id, redirect_url: "http://www.google.com", api_key: @ap_key, current_app_id: @c.app_ids[0]}
				expect(response.code).to eq("302")
				expect(response).to redirect_to(root_path)
				expect(@admin.errors.full_messages).to be_empty         		
			end

		end


		context " -- invalid api key with redirect url" do 

			it " -- yields new session" do 

				get new_admin_session_path,{api_key: "dog", redirect_url:"http://www.google.com", current_app_id: @c.app_ids[0]}
				res = assigns(:admin)
				expect(response.code).to eq("200")
				expect(session[:client]).to be_nil
				expect(session[:redirect_url]).to be_nil
				expect(res).not_to be_nil
				expect(res.errors.full_messages).to be_empty 


			end

			it " -- create session successfully,but does not redirect", :test_helper => true do 
				post admin_session_path, {admin: {login: @u.email, password: "password"}, api_key:"dog", redirect_url:"http://www.google.com", current_app_id: @c.app_ids[0]}
				res = assigns(:admin)
				expect(session[:client]).to be_nil
				expect(session[:redirect_url]).to be_nil
				expect(res).not_to be_nil
				expect(response).to redirect_to(admin_after_sign_in_path)
				expect(res.errors.full_messages).to be_empty

			end

			it " -- destory session loads" do 
				sign_in_as_a_valid_and_confirmed_admin
				delete destroy_admin_session_path,{:id => @admin.id, api_key:"dog", redirect_url:"http://www.google.com", current_app_id: @c.app_ids[0]}
				res = assigns(:admin)
				expect(session[:client]).to be_nil
				expect(session[:redirect_url]).to be_nil
				expect(response.code).to eq("302")
				expect(response).to redirect_to(root_path)

			end


		end


		context " -- no api key with redirect url" do 

			it " -- yields new session" do 

				get new_admin_session_path,{ redirect_url:"http://www.google.com", current_app_id: @c.app_ids[0]}
				res = assigns(:admin)
				expect(response.code).to eq("200")
				expect(session[:client]).to be_nil
				expect(session[:redirect_url]).to be_nil
				expect(res).not_to be_nil
				expect(res.errors.full_messages).to be_empty 

			end

			it " -- create session successfully, but does not redirect" do 
				post new_admin_session_path, {admin: attributes_for(:admin),  redirect_url:"http://www.google.com", current_app_id: @c.app_ids[0]}
				res = assigns(:admin)
				expect(response.code).to eq("200")
				expect(session[:client]).to be_nil
				expect(session[:redirect_url]).to be_nil
				expect(res).not_to be_nil
				expect(res.errors.full_messages).to be_empty 
			end

			it " -- destory session loads" do 
				sign_in_as_a_valid_and_confirmed_admin
				delete destroy_admin_session_path,{:id => @admin.id,  redirect_url:"http://www.google.com", current_app_id: @c.app_ids[0]}
				expect(session[:client]).to be_nil
				expect(session[:redirect_url]).to be_nil
				expect(response.code).to eq("302")
				expect(response).to redirect_to(root_path)
			end

	
		end


		context " -- no api key, no redirect url" do 

			it " -- yields new session" do 

				get new_admin_session_path
				res = assigns(:admin)
				expect(response.code).to eq("200")
				expect(res).not_to be_nil
				expect(res.errors.full_messages).to be_empty 
			end

			it " -- create session successfully, but does not redirect" do 
				post new_admin_session_path, {admin: attributes_for(:admin)}
				res = assigns(:admin)
				expect(response.code).to eq("200")
				expect(res).not_to be_nil
				expect(res.errors.full_messages).to be_empty 
			end

			it " -- destory session loads" do 
				sign_in_as_a_valid_and_confirmed_admin
				delete destroy_admin_session_path,{:id => @admin.id}
				expect(response.code).to eq("302")
			end

		end

	end

	context " -- json requests " do 

		before(:example) do 
			ActionController::Base.allow_forgery_protection = true
	        Admin.delete_all
	        Auth::Client.delete_all
	        @u = Admin.new(attributes_for(:admin_confirmed))
	        @u.save
	        @c = Auth::Client.where(:resource_id => @u.id).first
	        @c.api_key = "test"
	        @c.redirect_urls = ["http://www.google.com"]
	        @c.app_ids << "test_app_id"
	        @c.versioned_update
	        @ap_key = @c.api_key
		end

		after(:example) do 
			session.delete(:client)
			session.delete(:redirect_url)
		end

		before(:each) do 
			@headers = { "CONTENT_TYPE" => "application/json" , "ACCEPT" => "application/json", "X-Admin-Token" => @u.authentication_token, "X-Admin-Es" => @u.client_authentication["test_app_id"], "X-Admin-Aid" => "test_app_id"}
		end

		context " -- no api key" do 

			it " -- new session returns not authenticated" do 
				get new_admin_session_path,nil,@headers
        		expect(response.code).to eq("406")
			end

			it " -- create session retursn not authenticated" do 
				post new_admin_session_path, {admin: attributes_for(:admin)}.to_json, @headers
        		expect(response.code).to eq("401")
			end

			it " -- destroy session returns not authenticated" do 
				
				a = {:id => @u.id}
		        delete destroy_admin_session_path, a.to_json, @headers
		        expect(response.code).to eq("406")
			end

		end

		context " -- invalid api key " do 

			it " -- new session returns not authenticated" do 
				get new_admin_registration_path,nil,@headers
        		expect(response.code).to eq("401")

			end

			it " -- create session retursn not authenticated" do 
				post new_admin_session_path, {admin: attributes_for(:admin)}.to_json, @headers
        		expect(response.code).to eq("401")
			end

			it " -- destroy session returns not authenticated" do 

				a = {:id => @u.id}
		        delete destroy_admin_session_path, a.to_json, @headers
		        expect(response.code).to eq("406")
			end

		end

		context " -- valid api key" do 

			it " -- returns 406 when calling GET" do 
				
				get new_admin_session_path, {api_key: @ap_key, current_app_id: @c.app_ids[0]}, @headers
				expect(response.code).to eq("406")
				
			end

			it " -- returns the auth key and es when calling CREATE", :json_test => true do 
				
				
				params = {admin: {login: @u.email, password: "password"}, api_key: @ap_key, current_app_id: @c.app_ids[0]}
				
				post admin_session_path, params.to_json, @headers
        		expect(response.code).to eq("201")
        		admin_hash = JSON.parse(response.body)
        		expect(admin_hash.keys).to match_array(["authentication_token","es"])
        		
			end

			it " -- returns 406 when calling DESTROY" do 
				a = {:id => @u.id, :api_key => @ap_key, current_app_id: @c.app_ids[0]}
		        delete destroy_admin_session_path, a.to_json, @headers
		        expect(response.code).to eq("406")
			end

		end

	end

	context " -- multiple clients -- ",:order => :defined do 

		before(:all) do 
			##create first admin and associated client.
			Admin.delete_all
			Auth::Client.delete_all
			@u = Admin.new(attributes_for(:admin_confirmed))
	        #@u.set_client_authentication("test_app_id")
	        @u.save
	        @c = Auth::Client.where(:resource_id => @u.id).first
	        @c.api_key = "test"
	        @c.redirect_urls = ["http://www.google.com"]
	        @c.app_ids << "test_app_id"
	        @c.versioned_update
	        @ap_key = @c.api_key

			##create another admin and associated other client.
			@u2 = Admin.new(attributes_for(:admin_confirmed))
	        #@u2.set_client_authentication("test_app_id2")
	        @u2.save
			@c2 = Auth::Client.where(:resource_id => @u2.id).first
	        @c2.api_key = "test2"
	        @c2.redirect_urls = ["http://www.yahoo.com"]
	        @c2.app_ids << "test_app_id2"
	        @c2.versioned_update
	        @ap_key2 = @c2.api_key
	        ActionController::Base.allow_forgery_protection = false
		end

		it " -- signs in admin using first client -- " do 
			params = {admin: {login: @u.email, password: "password"}, api_key: @ap_key, current_app_id: @c.app_ids[0]}
			post admin_session_path, params
		end

		it "-- signs in admin using second client -- " do 
			params = {admin: {login: @u.email, password: "password"}, api_key: @ap_key2, current_app_id: @c2.app_ids[0]}
				
			post new_admin_session_path, params
			@signed_in_admin = assigns(:admin)
			expect(@signed_in_admin.client_authentication[@c.app_ids[0]]).not_to be_nil	
			expect(@signed_in_admin.client_authentication[@c2.app_ids[0]]).not_to be_nil
		end

	end

	context " -- same client with multiple app ids -- " do 

		before(:all) do 
			##create first admin and associated client.
			Admin.delete_all
			Auth::Client.delete_all
			@u = Admin.new(attributes_for(:admin_confirmed))
	        
	        @u.save
	        @c = Auth::Client.where(:resource_id => @u.id).first
	        @c.api_key = "test"
	        @c.redirect_urls = ["http://www.google.com"]
	        @c.app_ids << "test_app_id"
	        @c.app_ids << "test_app_id2"
	        @c.versioned_update
	        @ap_key = @c.api_key
	    end

	    it " -- signs in admin with first app id -- " do 
	    	params = {admin: {login: @u.email, password: "password"}, api_key: @ap_key, current_app_id: @c.app_ids[0]}
			post new_admin_session_path, params
	    end

	    it " -- signs in admin with second app id -- " do 
	    	params = {admin: {login: @u.email, password: "password"}, api_key: @ap_key, current_app_id: @c.app_ids[1]}
			post new_admin_session_path, params
	    	@signed_in_admin = assigns(:admin)
			expect(@signed_in_admin.client_authentication[@c.app_ids[0]]).not_to be_nil
			expect(@signed_in_admin.client_authentication[@c.app_ids[1]]).not_to be_nil	
	    end

	end


end

