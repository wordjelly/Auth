require 'rails_helper'
RSpec.describe Auth::Workflow::Step, type: :model, :step_model => true do

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

	context " -- " do 

		context " -- loads from json file -- " do 

			it " -- loads a single cart item, with one specification -- " do 

				cart_items = load_cart_items_from_json("/home/bhargav/Github/auth/spec/test_json_assemblies/specifications/1.json")
				## now we want to test the specifications.
				expect(cart_items.first.specifications.size).to eq(1)

			end

		end

		context " -- start time range -- " do 

			## json files with a single cart item and different specifications are to be created.
			## first a product will have to be created that matches the cart_item id.

			it " -- raises start time range not found if a selected start time range is not present -- " do 

				cart_items = load_cart_items_from_json("/home/bhargav/Github/auth/spec/test_json_assemblies/specifications/2.json")

				expect{cart_items.first.specifications.first.start_time_range}.to raise_error("start time range not selected")

			end

			it " -- raises no matching date if nearest date matching spec could not be found -- " do 

				cart_items = load_cart_items_from_json("/home/bhargav/Github/auth/spec/test_json_assemblies/specifications/4.json")

				expect{cart_items.first.specifications.first.start_time_range}.to raise_error("matching date could not be found with specification")
				
			end

			it " -- finds nearest matching date and returns a start time range -- " do 

				cart_items = load_cart_items_from_json("/home/bhargav/Github/auth/spec/test_json_assemblies/specifications/3.json")

				cart_items.first.specifications.first.start_time_range


			end

		end


		context " -- location -- " do 

			it " -- returns the location ids if they have been selected -- " do 

				cart_items = load_cart_items_from_json("/home/bhargav/Github/auth/spec/test_json_assemblies/specifications/5.json")

				puts JSON.pretty_generate(cart_items.first.specifications.first.attributes)

				location_ids = cart_items.first.specifications.first.location[:location_ids]	


				expect(location_ids.size).to eq(2)			

			end

			it " -- returns the location within radius and lat and long if those have been provided -- " do 

				cart_items = load_cart_items_from_json("/home/bhargav/Github/auth/spec/test_json_assemblies/specifications/6.json")

				location_info = cart_items.first.specifications.first.location	

				expect(location_info[:within_radius]).not_to be_nil
				expect(location_info[:origin_location]).not_to be_nil
				expect(location_info[:location_categories]).not_to be_nil


			end

		end

	end

end