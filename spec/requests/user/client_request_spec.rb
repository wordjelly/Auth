require "rails_helper"

RSpec.describe "client request spec", :client => true, :type => :request do 

	before(:all) do 
		## create a confirmed user
		@u = User.new(attributes_for(:user_confirmed))
        @u.save
		## create another confirmed user
		@u2 = User.new(attributes_for(:user_confirmed))
		@u2.save
		## create a confirmed admin user
		@admin = Admin.new(attributes_for(:admin_confirmed))
		@admin.save
	end

	context " -- json requests -- " do 
		it " -- does not respond to json request -- " do 
			get client_path(:id => @u.id.to_s),nil,{ "CONTENT_TYPE" => "application/json" , "ACCEPT" => "application/json"}
			expect(response.code).to eq("401")
		end
	end

	context " -- web app requests -- " do 
		it " -- returns not authenticated if no one is signed in -- " do 

			get client_path(:id => @u.id.to_s)
			expect(response).to redirect_to(new_user_session_path)
		end

		it " -- returns not allowed if client belongs to another user -- " do 

			sign_in(@u2)
			get client_path(:id => @u.id.to_s)
			expect(response.body).to eq("client does not belong to user")

		end

		it " -- goes through if admin is looking at a users client -- " do 
			sign_in(@admin)
			get client_path(:id => @u.id.to_s)
			expect(response.code).to eq("200")
		end

		it " -- shows the client -- " do 
			sign_in(@u)
			get client_path(:id => @u.id.to_s)
			expect(response.code).to eq("200")
			client = assigns(:client)
			expect(client.resource_id.to_s).to eq(@u.id.to_s)
		end

		it " -- updates the client with an app id if add_app_id is passed into the update request.", :client_update => true do 
			sign_in(@u)
			client = Auth::Client.find(@u.id.to_s)
			
			put client_path(:id => @u.id.to_s), :client => {:add_app_id => "anything"}
			
			expect(response.code).to eq("200")
			client = assigns(:client)
			expect(client.app_ids).not_to be_empty
		end
	end

end