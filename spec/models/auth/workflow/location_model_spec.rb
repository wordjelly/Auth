require 'rails_helper'
RSpec.describe Auth::Workflow::Location, type: :model, :location_model => true do

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
			Auth.configuration.location_class.constantize.delete_all
		end

		context " -- search for multiple requirements within a certain distance of a location -- " do 

			## so we want a location with the given requirements present in it, at the given time.
			it " -- loads and saves locations from json files -- " do 

				json_defintion = JSON.parse(IO.read("/home/bhargav/Github/auth/spec/test_json_assemblies/locations/1.json"))

				location_hashes = json_defintion["locations"]

				## how are we going to do a nearest search ?
				locations = location_hashes.map{|c|
					c = Auth.configuration.location_class.constantize.new(c)
					expect(c.save).to be_truthy
					c
				}

			end

			it " -- searches for locations within a given km radius of certain coordinates, that have all specified requirements, which are also not booked. -- ", :co_entity_search => true do 


				json_defintion = JSON.parse(IO.read("/home/bhargav/Github/auth/spec/test_json_assemblies/locations/1.json"))


				location_hashes = json_defintion["locations"]


				## how are we going to do a nearest search ?
				locations = location_hashes.map{|c|
					c = Auth.configuration.location_class.constantize.new(c)
					expect(c.save).to be_truthy
					c
				}				

				## now
				response = Auth.configuration.location_class.constantize.find_nearest_free_requirement_categories({:lat => 27.45 , :lng => 58.23},100,["1","1a"],[1,10],25)

				puts response.count

				response.each do |result|
					#puts result.attributes.to_s
				end

			end

			it " -- aggregation test -- ", :agg => true do 
				json_defintion = JSON.parse(IO.read("/home/bhargav/Github/auth/spec/test_json_assemblies/locations/1.json"))


				location_hashes = json_defintion["locations"]


				## how are we going to do a nearest search ?
				locations = location_hashes.map{|c|
					c = Auth.configuration.location_class.constantize.new(c)
					expect(c.save).to be_truthy
					c
				}	
				Auth.configuration.location_class.constantize.agg
			end

		end

	end

end