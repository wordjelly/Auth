require "rails_helper"

RSpec.describe "confirmation request spec", :type => :request do 

	before(:example) do 
		ActionController::Base.allow_forgery_protection = true
        Admin.delete_all
        Auth::Client.delete_all
        @u = Admin.new(attributes_for(:admin))
        @u.save
        @c = Auth::Client.new(:resource_id => @u.id, :api_key => "test")
        @c.redirect_urls = ["http://www.google.com"]
        @c.versioned_create
        @ap_key = @c.api_key
        @headers = { "CONTENT_TYPE" => "application/json" , "ACCEPT" => "application/json", "X-admin-Token" => @u.authentication_token, "X-admin-Es" => @u.es}
	end

	after(:example) do 
		
			session.delete(:client)
			session.delete(:redirect_url)
		
	end

	context "-- web app requests" do 

		before(:example) do 

			ActionController::Base.allow_forgery_protection = false

		end

		context "-- no api key" do 

			it "-- get request is successfull" do 
				
				get new_admin_confirmation_path,{}
				expect(response.code).to eq("200")		
			end

			it "-- create request is successfull" do				
				prev_msg_count = ActionMailer::Base.deliveries.size
				post admin_confirmation_path,{admin:{email: @u.email}}
				expect(response.code).to eq("302")
				message = ActionMailer::Base.deliveries[-1].to_s
    			rpt_index = message.index("confirmation_token")+"confirmation_token".length+1
    			confirmation_token = message[rpt_index...message.index("\"", rpt_index)]
    			new_msg_count = ActionMailer::Base.deliveries.size
    			expect(confirmation_token).not_to be(nil)
    			expect(new_msg_count - prev_msg_count).to eq(1)
			end

			it "-- show request is successfull" do 
				##should return redirect.
				message = ActionMailer::Base.deliveries[-1].to_s
    			rpt_index = message.index("confirmation_token")+"confirmation_token".length+1
    			confirmation_token = message[rpt_index...message.index("\"", rpt_index)]
    			get admin_confirmation_path,{confirmation_token: confirmation_token}
    			@u.reload
    			expect(@u.confirmed_at).not_to be(nil)
    			
			end

		end

		context "-- valid api key + redirect url" do 

			it "-- get request, client created, but no redirection" do 
				get new_admin_confirmation_path, {redirect_url: "http://www.google.com", api_key: @ap_key}
				expect(response.code).to eq("200")	

			end

			it "-- create request, client created, but no redirection" do 
				prev_msg_count = ActionMailer::Base.deliveries.size
				post admin_confirmation_path,{admin:{email: @u.email},redirect_url: "http://www.google.com", api_key: @ap_key}
				expect(response.code).to eq("302")
				message = ActionMailer::Base.deliveries[-1].to_s
    			rpt_index = message.index("confirmation_token")+"confirmation_token".length+1
    			confirmation_token = message[rpt_index...message.index("\"", rpt_index)]
    			new_msg_count = ActionMailer::Base.deliveries.size
    			expect(confirmation_token).not_to be(nil)
    			expect(new_msg_count - prev_msg_count).to eq(1)
    			expect(response).not_to redirect_to("http://www.google.com?authentication_token=#{@u.authentication_token}&es=#{@u.es}")
			end

			##redirection on show action is tested in the feature specs.
			##what that does is first visits the sign in page with a redirect url and api key, then goes to sign up, then signs up, then visits the confirmation_url page and is successfully redirected to the redirect url with the correct authentication_token and es.

		end

	end

	context "-- json requests " do 

		context "-- no api key" do 

			it "-- get request returns 406" do 
				get new_admin_confirmation_path,nil,@headers
        		expect(response.code).to eq("406")
			end

			it "-- create request returns not authenticated" do 
				post admin_confirmation_path,{admin:{email: @u.email}}.to_json,@headers
				expect(response.code).to eq("401")
			end

			it "-- show request returns not authenticated" do 
				get admin_confirmation_path,{confirmation_token: "dog"}.to_json,@headers
				expect(response.code).to eq("401")
			end

		end


		context "-- valid api key" do 


			it "-- get request returns 406" do 
				get new_admin_confirmation_path,{api_key: @ap_key}.to_json,@headers
        		expect(response.code).to eq("406")
			end

			it "-- create request works" do 
				prev_msg_count = ActionMailer::Base.deliveries.size
				

				post admin_confirmation_path,{admin:{email: @u.email}, api_key: @ap_key}.to_json,@headers
				
				message = ActionMailer::Base.deliveries[-1].to_s
    			rpt_index = message.index("confirmation_token")+"confirmation_token".length+1
    			confirmation_token = message[rpt_index...message.index("\"", rpt_index)]
    			new_msg_count = ActionMailer::Base.deliveries.size
    			expect(confirmation_token).not_to be(nil)
    			expect(new_msg_count - prev_msg_count).to eq(1)
    			expect(response.code).to eq("201")

			end

			it "-- show request works --" do 
				message = ActionMailer::Base.deliveries[-1].to_s
    			rpt_index = message.index("confirmation_token")+"confirmation_token".length+1
    			confirmation_token = message[rpt_index...message.index("\"", rpt_index)]
    			get admin_confirmation_path,{confirmation_token: confirmation_token, api_key: @ap_key}, @headers
    			@u.reload
    			expect(@u.confirmed_at).not_to be(nil)
    			expect(response.code).to eq("201")
			end

		end

	end

end