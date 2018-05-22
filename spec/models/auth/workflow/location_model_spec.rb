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

				#categories = ["a","b","c"]

				#options = {:speed => 20000, :coordinates => {:lat => 27.45, :lng => 58.22}, :within_radius => 10000, :categories => categories, :minute_ranges => [[0,100]]}

				query_array = 
				[
					{
						"start_time_range_beginning" => 0,
						"start_time_range_end" => 100,
						"duration" => 2,
						"location_categories" => ["1","2","3"],
						"categories" => [
							{
								"category" => "a",
								"capacity" => 1
							},
							{
								"category" => "b",
								"capacity" => 1
							},
							{
								"category" => "c",
								"capacity" => 1
							}
						]
					}
				]

				response = Auth.configuration.location_class.constantize.travel_to_point_with_entities(query_array,{:lat => 27.45, :lng => 58.22},50000,20000)

				total_results = 0
				#expected_result_minutes_in_asc_order = [1,2,3]
				
				response.each_with_index {|res,res_index|
					puts JSON.pretty_generate(res)
					total_results+=1
				}
				
				expect(total_results).to eq(1)

			end

=begin
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
=end
		end

		context " -- find entity -- ", :find_entity => true do 

			it " -- find entity without consumables -- " do 

				Auth.configuration.location_class.constantize.delete_all

				json_defintion = JSON.parse(IO.read("/home/bhargav/Github/auth/spec/test_json_assemblies/locations/2.json"))

				location_hashes = json_defintion["locations"]

				locations = location_hashes.map{|c|
					c = Auth.configuration.location_class.constantize.new(c)
					expect(c.save).to be_truthy
					c
				}

				
				query_array = 
				[
					{
						"start_time_range_beginning" => 0,
						"start_time_range_end" => 100,
						"duration" => 2,
						"location_id" => "first_location",
						"categories" => [
							{
								"category" => "a",
								"capacity" => 1
							},
							{
								"category" => "b",
								"capacity" => 1
							},
							{
								"category" => "c",
								"capacity" => 1
							}
						]
					}
				]

				response = Auth.configuration.location_class.constantize.find_entities_non_transport(query_array)
			
				## now it should find the entities,	
				total_results = 0
				response.each do |res|
					total_results+=1
				end			


				expect(total_results).to eq(1)

			end

			it " -- find entity works with location categories -- ", :find_entity_categories => true do 

				Auth.configuration.location_class.constantize.delete_all

				json_defintion = JSON.parse(IO.read("/home/bhargav/Github/auth/spec/test_json_assemblies/locations/2.json"))

				location_hashes = json_defintion["locations"]
				
				locations = location_hashes.map{|c|
					c = Auth.configuration.location_class.constantize.new(c)
					expect(c.save).to be_truthy
					c
				}


				query_array = 
				[
					{
						"start_time_range_beginning" => 0,
						"start_time_range_end" => 100,
						"duration" => 2,
						"location_categories" => ["1","2","3"],
						"categories" => [
							{
								"category" => "a",
								"capacity" => 1
							},
							{
								"category" => "b",
								"capacity" => 1
							},
							{
								"category" => "c",
								"capacity" => 1
							}
						]
					}
				]

				response = Auth.configuration.location_class.constantize.find_entities_non_transport(query_array)
			
				## now it should find the entities,	
				total_results = 0
				response.each do |res|
					
					total_results+=1
				end			

				expect(total_results).to eq(1)


			end

			it " -- find entity withing a radius -- ", :find_entity_in_radius => true do 
				
				Auth.configuration.location_class.constantize.delete_all

				json_defintion = JSON.parse(IO.read("/home/bhargav/Github/auth/spec/test_json_assemblies/locations/2.json"))

				location_hashes = json_defintion["locations"]

				locations = location_hashes.map{|c|
					c = Auth.configuration.location_class.constantize.new(c)
					expect(c.save).to be_truthy
					c
				}

				
				query_array = 
				[
					{
						"start_time_range_beginning" => 0,
						"start_time_range_end" => 100,
						"duration" => 2,
						"location_categories" => ["1","2","3"],
						"categories" => [
							{
								"category" => "a",
								"capacity" => 1
							},
							{
								"category" => "b",
								"capacity" => 1
							},
							{
								"category" => "c",
								"capacity" => 1
							}
						]
					}
				]

				response = Auth.configuration.location_class.constantize.find_entities_within_circle(query_array,{:lat => 27.45, :lng => 58.22},500000)
			
				## now it should find the entities,	
				total_results = 0
				response.each do |res|
					total_results+=1
				end			


				expect(total_results).to eq(1)

			end

=begin
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
=end
		end

=begin
		context " -- consumables query -- ", :consumables => true do 

			it " -- filters those minutes where consumables are not present -- " do 

				## okay so here we send a query for those locations which have a minute

				Auth.configuration.location_class.constantize.delete_all

				json_defintion = JSON.parse(IO.read("/home/bhargav/Github/auth/spec/test_json_assemblies/locations/2.json"))

				location_hashes = json_defintion["locations"]

				
				locations = location_hashes.map{|c|
					c = Auth.configuration.location_class.constantize.new(c)
					expect(c.save).to be_truthy
					c
				}

				consumable_one = Auth.configuration.consumable_class.constantize.new(:product_id => "first_product", :quantity => 1)

				consumable_two = Auth.configuration.consumable_class.constantize.new(:product_id => "second_product", :quantity => 2)
				

				options = {:duration => 2, :categories => ["a","b","c"], :minute_ranges => [[0,100]], :consumables => [consumable_one,consumable_two]}

				response = Auth.configuration.location_class.constantize.find_entity(options)

				response = response.to_a
				expect(response.size).to eq(0)

			end

			it " -- finds results if at least some minutes agree with the consumables requirements -- " do 

				Auth.configuration.location_class.constantize.delete_all

				json_defintion = JSON.parse(IO.read("/home/bhargav/Github/auth/spec/test_json_assemblies/locations/2.json"))

				location_hashes = json_defintion["locations"]

				
				locations = location_hashes.map{|c|
					c = Auth.configuration.location_class.constantize.new(c)
					expect(c.save).to be_truthy
					c
				}

				consumable_one = Auth.configuration.consumable_class.constantize.new(:product_id => "first_product", :quantity => 1)

			
				options = {:duration => 2, :categories => ["a","b","c"], :minute_ranges => [[0,100]], :consumables => [consumable_one]}

				response = Auth.configuration.location_class.constantize.find_entity(options)

				response = response.to_a
				expect(response.size).to eq(2)

			end

		end
=end
		context " -- transport query -- ", :transport => true do 

			it " -- returns a result with departs from location id and arrives at location id categories -- " do 

				## so the location is 
				Auth.configuration.location_class.constantize.delete_all

				json_defintion = JSON.parse(IO.read("/home/bhargav/Github/auth/spec/test_json_assemblies/locations/location_with_transport_information.json"))

				location_hashes = json_defintion["locations"]

				
				locations = location_hashes.map{|c|
					c = Auth.configuration.location_class.constantize.new(c)
					expect(c.save).to be_truthy
					c
				}

				location_info_array = 
				[
					{
						"start_time_range_beginning" => 0,
						"start_time_range_end" => 100,
						"duration" => 500,
						"location_id" => "first_location",
						"categories" => [
							{
								"category" => "a",
								"arrives_at_location_categories" => ["l1"],
								"transport_capacity" => 10
							}
						]
					}
				]

				response = Auth.configuration.location_class.constantize.find_entities_transport(location_info_array)

				total_results = 0
				response.each do |loc|
					puts JSON.pretty_generate(loc)
					total_results+=1
				end

				expect(total_results).to eq(1)

			end

		end


	end

end
