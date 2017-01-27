require "rails_helper"

RSpec.describe "session request spec", :type => :request do 

	before(:example) do 

		ActionController::Base.allow_forgery_protection = true
        User.delete_all
        Auth::Client.delete_all
        @u = User.new(attributes_for(:user_confirmed))
        @u.save
        @c = Auth::Client.new(:resource_id => @u.id, :api_key => "test")
        @c.redirect_urls = ["http://www.google.com"]
        @c.app_ids << "test_app_id"
        @c.versioned_create
        @ap_key = @c.api_key
        @headers = { "CONTENT_TYPE" => "application/json" , "ACCEPT" => "application/json", "X-User-Token" => @u.authentication_token, "X-User-Es" => @u.es}

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

				get new_user_session_path,{redirect_url: "http://www.google.com", api_key: @ap_key}
				expect(session[:client]).not_to be_nil
				expect(session[:redirect_url]).not_to be_nil
				
			end

			it " -- CREATE request, should redirect with the auth_token and es " do 
				
				post user_session_path,{redirect_url: "http://www.google.com", api_key: @ap_key, user: {email: @u.email, password: "password"}}
				@user = assigns(:user)
				expect(response.code).to eq("302")
				expect(response).to redirect_to("http://www.google.com?authentication_token=#{@u.authentication_token}&es=#{@u.es}")
				expect(@user).not_to be_nil
       			expect(@user.errors.full_messages).to be_empty 

			end

			it " -- DESTROY Request, should not redirect. " do 
				
				sign_in_as_a_valid_user
				delete destroy_user_session_path,{:id => @user.id, redirect_url: "http://www.google.com", api_key: @ap_key}
				expect(response.code).to eq("302")
				expect(response).to redirect_to(root_path)
				expect(@user.errors.full_messages).to be_empty         		
			end

		end


		context " -- invalid api key with redirect url" do 

			it " -- yields new session" do 

				get new_user_session_path,{api_key: "dog", redirect_url:"http://www.google.com"}
				res = assigns(:user)
				expect(response.code).to eq("200")
				expect(session[:client]).to be_nil
				expect(session[:redirect_url]).to be_nil
				expect(res).not_to be_nil
				expect(res.errors.full_messages).to be_empty 


			end

			it " -- create session successfully,but does not redirect" do 
				post new_user_session_path, {user: attributes_for(:user), api_key:"dog", redirect_url:"http://www.google.com"}
				res = assigns(:user)
				expect(response.code).to eq("200")
				expect(session[:client]).to be_nil
				expect(session[:redirect_url]).to be_nil
				expect(res).not_to be_nil
				expect(res.errors.full_messages).to be_empty

			end

			it " -- destory session loads" do 
				sign_in_as_a_valid_user
				delete destroy_user_session_path,{:id => @user.id, api_key:"dog", redirect_url:"http://www.google.com"}
				res = assigns(:user)
				expect(session[:client]).to be_nil
				expect(session[:redirect_url]).to be_nil
				expect(response.code).to eq("302")
				expect(response).to redirect_to(root_path)

			end


		end


		context " -- no api key with redirect url" do 

			it " -- yields new session" do 

				get new_user_session_path,{ redirect_url:"http://www.google.com"}
				res = assigns(:user)
				expect(response.code).to eq("200")
				expect(session[:client]).to be_nil
				expect(session[:redirect_url]).to be_nil
				expect(res).not_to be_nil
				expect(res.errors.full_messages).to be_empty 

			end

			it " -- create session successfully, but does not redirect" do 
				post new_user_session_path, {user: attributes_for(:user),  redirect_url:"http://www.google.com"}
				res = assigns(:user)
				expect(response.code).to eq("200")
				expect(session[:client]).to be_nil
				expect(session[:redirect_url]).to be_nil
				expect(res).not_to be_nil
				expect(res.errors.full_messages).to be_empty 
			end

			it " -- destory session loads" do 
				sign_in_as_a_valid_user
				delete destroy_user_session_path,{:id => @user.id,  redirect_url:"http://www.google.com"}
				expect(session[:client]).to be_nil
				expect(session[:redirect_url]).to be_nil
				expect(response.code).to eq("302")
				expect(response).to redirect_to(root_path)
			end

	
		end


		context " -- no api key, no redirect url" do 

			it " -- yields new session" do 

				get new_user_session_path
				res = assigns(:user)
				expect(response.code).to eq("200")
				expect(res).not_to be_nil
				expect(res.errors.full_messages).to be_empty 
			end

			it " -- create session successfully, but does not redirect" do 
				post new_user_session_path, {user: attributes_for(:user)}
				res = assigns(:user)
				expect(response.code).to eq("200")
				expect(res).not_to be_nil
				expect(res.errors.full_messages).to be_empty 
			end

			it " -- destory session loads" do 
				sign_in_as_a_valid_user
				delete destroy_user_session_path,{:id => @user.id}
				expect(response.code).to eq("302")
			end

		end

	end

	context " -- json requests " do 

		

		context " -- no api key" do 

			it " -- new session returns not authenticated" do 
				get new_user_session_path,nil,@headers
        		expect(response.code).to eq("406")

			end

			it " -- create session retursn not authenticated" do 
				post new_user_session_path, {user: attributes_for(:user)}.to_json, @headers
        		expect(response.code).to eq("401")
			end

			it " -- destroy session returns not authenticated" do 
				
				a = {:id => @u.id}
		        delete destroy_user_session_path, a.to_json, @headers
		        expect(response.code).to eq("406")
			end

		end

		context " -- invalid api key " do 

			it " -- new session returns not authenticated" do 
				get new_user_registration_path,nil,@headers
        		expect(response.code).to eq("401")

			end

			it " -- create session retursn not authenticated" do 
				post new_user_session_path, {user: attributes_for(:user)}.to_json, @headers
        		expect(response.code).to eq("401")
			end

			it " -- destroy session returns not authenticated" do 

				a = {:id => @u.id}
		        delete destroy_user_session_path, a.to_json, @headers
		        expect(response.code).to eq("406")
			end

		end

		context " -- valid api key" do 

			it " -- returns 406 when calling GET" do 
				
				get new_user_session_path, {api_key: @ap_key}, @headers
				expect(response.code).to eq("406")
				
			end

			it " -- returns the auth key and es when calling CREATE" do 
				
				
				params = {user: {email: @u.email, password: "password"}, api_key: @ap_key}
				
				post new_user_session_path, params.to_json, @headers
        		expect(response.code).to eq("201")
        		user_hash = JSON.parse(response.body)
        		expect(user_hash.keys).to match_array(["authentication_token","es"])
        		
			end


			it " -- returns 406 when calling DESTROY" do 
				a = {:id => @u.id, :api_key => @ap_key}
		        delete destroy_user_session_path, a.to_json, @headers
		        expect(response.code).to eq("406")
			end

		end

	end

	

end
