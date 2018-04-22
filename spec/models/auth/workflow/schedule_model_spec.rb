require 'rails_helper'
RSpec.describe Auth::Workflow::Schedule, type: :model, :schedule_model => true do

	context " -- wrapper -- " do 

		before(:all) do
			User.delete_all

			## create one non admin user
			@u = User.new(attributes_for(:user_confirmed))
	        @u.save
	        @c = Auth::Client.new(:resource_id => @u.id, :api_key => "test", :app_ids => ["testappid"])
	        @c.redirect_urls = ["http://www.google.com"]
	        @c.versioned_create
	        @u.client_authentication["testappid"] = "testestoken"
	        @u.save
	        @ap_key = @c.api_key
	        @headers = { "CONTENT_TYPE" => "application/json" , "ACCEPT" => "application/json", "X-User-Token" => @u.authentication_token, "X-User-Es" => @u.client_authentication["testappid"], "X-User-Aid" => "testappid"}

			## create one admin user.
			@admin = User.new(attributes_for(:admin_confirmed))
	        @admin.admin = true
	        @admin.client_authentication["testappid"] = "testestoken2"
	        @admin.save
	        @admin_headers = { "CONTENT_TYPE" => "application/json" , "ACCEPT" => "application/json", "X-User-Token" => @admin.authentication_token, "X-User-Es" => @admin.client_authentication["testappid"], "X-User-Aid" => "testappid"}
		end

		context " -- load from json file -- " do 

			it " -- creates schedules -- " do 
				response = load_and_create_schedules_bookings_and_requirements("/home/bhargav/Github/auth/spec/test_json_assemblies/two_schedules_two_requirements_two_bookings_two_slots.json",@admin,@u)
				## does this save the schedules ?
				schedules = response[:schedules]
				assembly = response[:assembly]
				cart_items = response[:cart_items]
				expect(schedules.size).to eq(2)
				
			end

			it " -- creates requirements specified in schedule -- " do 
				expect(Auth.configuration.requirement_class.constantize.all.size).to eq(0)
				response = load_and_create_schedules_bookings_and_requirements("/home/bhargav/Github/auth/spec/test_json_assemblies/two_schedules_two_requirements_two_bookings_two_slots.json",@admin,@u)
				## does this save the schedules ?
				schedules = response[:schedules]
				assembly = response[:assembly]
				cart_items = response[:cart_items]
				expect(schedules.size).to eq(2)
				
			end

		end

		context " -- search -- " do 
			
			it " -- searches for requirements of a particular category -- " do 
				
			end

			it " -- searches for requirements of a particular category and a location preference -- " do 

			end

			it " -- searches for a particular requirement id -- " do

			end

		end

	end

end