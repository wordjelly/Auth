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


		context " -- minutes and entities -- ", :load_location => true do 

			it " -- loads from json file -- " do 

				json_defintion = JSON.parse(IO.read("/home/bhargav/Github/auth/spec/test_json_assemblies/locations/2.json"))

				location_hashes = json_defintion["locations"]

				## how are we going to do a nearest search ?
				locations = location_hashes.map{|c|
					c = Auth.configuration.location_class.constantize.new(c)
					expect(c.save).to be_truthy
					c
				}

			end

		end

		## first of all we need the combined capacity at each minute for each category.
		## so first let me see if this search works, to produce the results as we need and then let me modify the requirements.

		context " -- travel search -- ", :travel_search => true  do 

			it " -- finds requirements from categories a, b at the nearest location, free for time taken to travel between that location and given point. -- " do 

				Auth.configuration.location_class.constantize.delete_all

				json_defintion = JSON.parse(IO.read("/home/bhargav/Github/auth/spec/test_json_assemblies/locations/2.json"))

				location_hashes = json_defintion["locations"]

				
				locations = location_hashes.map{|c|
					c = Auth.configuration.location_class.constantize.new(c)
					expect(c.save).to be_truthy
					c
				}

				categories = ["a","b","c"]

				options = {:speed => 20000, :coordinates => {:lat => 27.45, :lng => 58.22}, :within_radius => 10000, :categories => categories, :minute_ranges => [[0,100]]}

				response = Auth.configuration.location_class.constantize.loc(options)

				total_results = 0
				expected_result_minutes_in_asc_order = [1,2,3]
				
				response.each do |res|
					expect(res["minutes"]).not_to be_empty
					res["minutes"].each do |minute|
						expect(minute["categories"]).not_to be_empty
						minute["categories"].each do |category|
							expect(category["capacity"]).to be > 0
							expect(categories.include? category["category"]).to be_truthy
							expect(category["entities"]).not_to be_empty
						end
					end
					total_results+=1
				end
				
				expect(total_results).to eq(2)

			end

			it " -- filters with location ids and categories if they are passed into the options -- " do 

				Auth.configuration.location_class.constantize.delete_all

				json_defintion = JSON.parse(IO.read("/home/bhargav/Github/auth/spec/test_json_assemblies/locations/2.json"))

				location_hashes = json_defintion["locations"]

				
				locations = location_hashes.map{|c|
					c = Auth.configuration.location_class.constantize.new(c)
					expect(c.save).to be_truthy
					c
				}

				options = {:speed => 20000, :coordinates => {:lat => 27.45, :lng => 58.22}, :within_radius => 10000, :categories => ["a","b","c"], :minute_ranges => [[0,100]], :location_categories => ["1","2","3"],}

				response = Auth.configuration.location_class.constantize.loc(options)

				total_results = 0
				
				response.each do |res|
				
					total_results+=1
				end
				
				expect(total_results).to eq(1)



			end

		end

		context " -- find entity -- ", :find_entity => true do 

			it " -- finds entities of the required categories, given minute range, location id, or location categories, and groups by minutes and sorts in 	ascending order -- " do 

				Auth.configuration.location_class.constantize.delete_all

				json_defintion = JSON.parse(IO.read("/home/bhargav/Github/auth/spec/test_json_assemblies/locations/2.json"))

				location_hashes = json_defintion["locations"]

				
				locations = location_hashes.map{|c|
					c = Auth.configuration.location_class.constantize.new(c)
					expect(c.save).to be_truthy
					c
				}

				options = {:duration => 2, :categories => ["a","b","c"], :minute_ranges => [[0,100]]}

				response = Auth.configuration.location_class.constantize.find_entity(options)
			
				## now it should find the entities,	
				total_results = 0
				response.each do |res|
					total_results+=1
				end			


				expect(total_results).to eq(2)

			end

			it " -- find entity works with location categories -- " do 

				Auth.configuration.location_class.constantize.delete_all

				json_defintion = JSON.parse(IO.read("/home/bhargav/Github/auth/spec/test_json_assemblies/locations/2.json"))

				location_hashes = json_defintion["locations"]

				
				locations = location_hashes.map{|c|
					c = Auth.configuration.location_class.constantize.new(c)
					expect(c.save).to be_truthy
					c
				}

				options = {:duration => 2, :categories => ["a","b","c"], :minute_ranges => [[0,100]], :location_categories => ["5"]}

				response = Auth.configuration.location_class.constantize.find_entity(options)
			
				## now it should find the entities,	
				total_results = 0
				response.each do |res|
					
					total_results+=1
				end			


				expect(total_results).to eq(1)

			end

			it " -- if location ids and categories are provided, both are considered. -- ", :find_entity_location_ids do 

				Auth.configuration.location_class.constantize.delete_all

				json_defintion = JSON.parse(IO.read("/home/bhargav/Github/auth/spec/test_json_assemblies/locations/2.json"))

				location_hashes = json_defintion["locations"]

				
				locations = location_hashes.map{|c|
					c = Auth.configuration.location_class.constantize.new(c)
					expect(c.save).to be_truthy
					c
				}

				# since the first location has a category of 5, we will ask for category of second location and id of the first location.
				# so it should return no results.
				options = {:duration => 2, :categories => ["1","2","3"], :minute_ranges => [[0,100]], :location_ids => [locations.first.id.to_s]}

				response = Auth.configuration.location_class.constantize.find_entity(options)
			
				## now it should find the entities,	
				total_results = 0
				response.each do |res|
					total_results+=1
				end			


				expect(total_results).to eq(0)


			end

		end

	end

end
