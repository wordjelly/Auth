require "rails_helper"

RSpec.describe "session request spec", :type => :request do 

	context " -- web app requests" do 

		context " -- valid api key with redirect url" do 

		end

		context " -- invalid api key with redirect url" do 


		end

		context " -- no api key with redirect url" do 


		end

		context " -- no api key, no redirect url" do 

			it " -- yields new session" do 

				get new_user_session_path
				res = assigns(:user)
				expect(response.code).to eq("200")
				expect(res).not_to be_nil

			end

			it " -- create session successfully" do 
				post "/authenticate/users/sign_in", {user: attributes_for(:user)}
				res = assigns(:user)
				expect(response.code).to eq("200")
				expect(res).not_to be_nil
			end

			it " -- destory session loads" do 
				##sign in as a valid user
				sign_in_as_a_valid_user
				delete "/authenticate/users/sign_out",{:id => @user.id}
				expect(response.code).to eq("302")
			end

		end

	end

	context " -- json requests " do 

		before(:example) do 

			ActionController::Base.allow_forgery_protection = true
	        User.delete_all
	        Auth::Client.delete_all
	        @u = User.new(attributes_for(:user))
	        @u.save
	        @c = Auth::Client.new(:user_id => @u.id, :api_key => "test")
	        @c.redirect_urls = ["http://www.google.com"]
	        @c.versioned_create
	        @ap_key = @c.api_key
	        @headers = { "CONTENT_TYPE" => "application/json" , "ACCEPT" => "application/json", "X-User-Token" => @u.authentication_token, "X-User-Es" => @u.es}


		end

		context " -- no api key" do 

			it " -- new session returns not authenticated" do 
				get new_user_registration_path,nil,@headers
        		expect(response.code).to eq("401")

			end

			it " -- create session retursn not authenticated" do 
				post "/authenticate/users/sign_in", {user: attributes_for(:user)}.to_json, @headers
        		expect(response.code).to eq("401")
			end

			it " -- destroy session returns not authenticated" do 
				
				a = {:id => @u.id}
		        delete "/authenticate/users/sign_out", a.to_json, @headers
		        expect(response.code).to eq("406")
			end

		end

		context " -- invalid api key " do 

			it " -- new session returns not authenticated" do 
				get new_user_registration_path,nil,@headers
        		expect(response.code).to eq("401")

			end

			it " -- create session retursn not authenticated" do 
				post "/authenticate/users/sign_in", {user: attributes_for(:user)}.to_json, @headers
        		expect(response.code).to eq("401")
			end

			it " -- destroy session returns not authenticated" do 

				a = {:id => @u.id}
		        delete "/authenticate/users/sign_out", a.to_json, @headers
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
				puts params.to_json
				post "/authenticate/users/sign_in", params.to_json, @headers
        		expect(response.code).to eq("201")
        		user_hash = JSON.parse(response.body)
        		expect(user_hash.keys).to match_array(["authentication_token","es"])
        		
			end


			it " -- returns 406 when calling DESTROY" do 
				a = {:id => @u.id, :api_key => @ap_key}
		        delete "/authenticate/users/sign_out", a.to_json, @headers
		        expect(response.code).to eq("406")
			end

		end

	end

end