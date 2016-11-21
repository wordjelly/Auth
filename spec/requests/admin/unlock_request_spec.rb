require "rails_helper"

RSpec.describe "unlock request spec", :type => :request do 	

	before(:example) do 
		ActionController::Base.allow_forgery_protection = true
        Admin.delete_all
        Auth::Client.delete_all
        @u = Admin.new(attributes_for(:admin_confirmed))
        @u.save
        @u.lock_access!
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

	context "--- web app requests--" do 

		before(:example) do 

			ActionController::Base.allow_forgery_protection = false

		end


		context "-- valid api key -- " do 

			it " -- new -- " do 

				get new_admin_unlock_path,{redirect_url: "http://www.google.com", api_key: @ap_key}
				expect(response.code).to eq("200")

			end

			it " -- create -- " do 

				prev_msg_count = ActionMailer::Base.deliveries.size
				post admin_unlock_path,{admin:{email: @u.email},redirect_url: "http://www.google.com", api_key: @ap_key}
				expect(response.code).to eq("302")
				message = ActionMailer::Base.deliveries[-1].to_s
    			rpt_index = message.index("unlock_token")+"unlock_token".length+1
    			unlock_token = message[rpt_index...message.index("\"", rpt_index)]
    			new_msg_count = ActionMailer::Base.deliveries.size
    			expect(unlock_token).not_to be(nil)
    			expect(new_msg_count - prev_msg_count).to eq(1)
				

			end	

			it " -- show -- " do 

				message = ActionMailer::Base.deliveries[-1].to_s
    			rpt_index = message.index("unlock_token")+"unlock_token".length+1
    			unlock_token = message[rpt_index...message.index("\"", rpt_index)]

    			get admin_unlock_path,{unlock_token: unlock_token}
    			@u.reload
    			expect(@u.unlock_token).to be_nil
    			expect(@u.locked_at).to be_nil
    			
			end

		end

		context " -- valid api key + redirect_url -- " do 

			it " -- new should not redirect" do 
				get new_admin_unlock_path, {redirect_url: "http://www.google.com", api_key: @ap_key}
				expect(response.code).to eq("200")	
			end

			it " -- create should not redirect" do 
				prev_msg_count = ActionMailer::Base.deliveries.size
				post admin_unlock_path,{admin:{email: @u.email},redirect_url: "http://www.google.com", api_key: @ap_key}
				expect(response.code).to eq("302")
				message = ActionMailer::Base.deliveries[-1].to_s
    			rpt_index = message.index("unlock_token")+"unlock_token".length+1
    			unlock_token = message[rpt_index...message.index("\"", rpt_index)]
    			new_msg_count = ActionMailer::Base.deliveries.size
    			expect(unlock_token).not_to be(nil)
    			expect(new_msg_count - prev_msg_count).to eq(1)
				expect(response).not_to redirect_to("http://www.google.com?authentication_token=#{@u.authentication_token}&es=#{@u.es}")
			end

			it " -- show should not redirect" do 
				message = ActionMailer::Base.deliveries[-1].to_s
    			rpt_index = message.index("unlock_token")+"unlock_token".length+1
    			unlock_token = message[rpt_index...message.index("\"", rpt_index)]

    			get admin_unlock_path,{unlock_token: unlock_token}
    			@u.reload
    			expect(@u.unlock_token).to be_nil
    			expect(@u.locked_at).to be_nil
    			expect(response).not_to redirect_to("http://www.google.com?authentication_token=#{@u.authentication_token}&es=#{@u.es}")
			end

		end

	end


	context "-- json request -- " do 

		
		context " -- valid api key -- " do 

			it " -- new -- " do 
				
				get new_admin_unlock_path,{api_key: @ap_key}.to_json,@headers
				expect(response.code).to eq("406")

			end

			it " -- create -- " do 

				prev_msg_count = ActionMailer::Base.deliveries.size
				post admin_unlock_path,{admin:{email: @u.email},api_key: @ap_key}.to_json,@headers
				
				message = ActionMailer::Base.deliveries[-1].to_s
    			rpt_index = message.index("unlock_token")+"unlock_token".length+1
    			unlock_token = message[rpt_index...message.index("\"", rpt_index)]
    			new_msg_count = ActionMailer::Base.deliveries.size
    			expect(unlock_token).not_to be(nil)
    			expect(new_msg_count - prev_msg_count).to eq(1)
				expect(response.code).to eq("201")

			end	

			it " -- show -- " do 
				
				message = ActionMailer::Base.deliveries[-1].to_s
    			rpt_index = message.index("unlock_token")+"unlock_token".length+1
    			unlock_token = message[rpt_index...message.index("\"", rpt_index)]
    			get admin_unlock_path,{unlock_token: unlock_token, api_key: @ap_key},@headers
    			@u.reload
    			expect(@u.unlock_token).to be_nil
    			expect(@u.locked_at).to be_nil
				expect(response.code).to eq("201")    			

			end

		end

	end

end