require 'rails_helper'
RSpec.describe Auth::Work::Schedule, type: :model, :schedule_model => true do

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

		before(:example) do 
			Auth::Work::Schedule.delete_all
		end

		context " --- create --- " do 

			it " -- creates schedule if none exists in the overlapping time range -- " do 

				s = Auth::Work::Schedule.new
				s.start_time = Time.new(2002,10,30)
				s.end_time = Time.new(2002,10,31)
				s.location_id = "first_location"
				s.for_object_id = "user_one"
				s.for_object_class = "User"
				s.create_prev_not_exists
				expect(Auth::Work::Schedule.all.size).to eq(1)

				s = Auth::Work::Schedule.new
				s.start_time = Time.new(2002,10,30)
				s.end_time = Time.new(2002,10,31)
				s.location_id = "first_location"
				s.for_object_id = "user_one"
				s.for_object_class = "User"
				s.create_prev_not_exists
				expect(Auth::Work::Schedule.all.size).to eq(1)

			end

			it " -- creates new schedule if location is different -- " do 

				s = Auth::Work::Schedule.new
				s.start_time = Time.new(2002,10,30)
				s.end_time = Time.new(2002,10,31)
				s.location_id = "first_location"
				s.for_object_id = "user_one"
				s.for_object_class = "User"
				s.create_prev_not_exists
				expect(Auth::Work::Schedule.all.size).to eq(1)

				s = Auth::Work::Schedule.new
				s.start_time = Time.new(2002,10,30)
				s.end_time = Time.new(2002,10,31)
				s.location_id = "second_location"
				s.for_object_id = "user_one"
				s.for_object_class = "User"
				s.create_prev_not_exists
				expect(Auth::Work::Schedule.all.size).to eq(2)				

			end

		end


	end

end