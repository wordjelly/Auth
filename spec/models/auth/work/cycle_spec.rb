require 'rails_helper'
RSpec.describe Auth::Work::Cycle, type: :model, :cycle_model => true do

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
			Auth::Work::Cycle.delete_all
		end

		context " --- create --- " do 

			## where are the cycles to be added ?
			## inside the products
			## so first we create a product and then add ten cycles to it.
			it " -- adds some cycles to a product -- " do 

				product = Auth.configuration.product_class.constantize.new
				product.resource_id = @admin.id.to_s
                product.resource_class = @admin.class.name
                product.price = 10.00
                product.signed_in_resource = @admin
                cycle = Auth::Work::Cycle.new
                cycle.duration = 10
                cycle.time_to_next_cycle = 20
                product.cycles << cycle
                expect(product.save).to be_truthy

			end
			
		end

		context " -- create cycles inside minutes -- " do 

			## see a cycle may require n number of different products
			## so it has to basically assemble a hash of cycle codes, and counts and types of workers and entities that it needs
			## then we can create the cycles out of that.
			## so the cycle will have to have a requirements hash
			## type -> count
			it " -- finds and iterates applicable schedules, and adds all the cycles from them  -- " do 

				## first assemble the cycles and what intervals they have to be done on in the minutes
				## then find the schedules in those minutes
				

			end			

		end

		## after this is the incoming travellers


	end

end