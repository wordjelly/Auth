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


		context " -- minutes and entities -- ", :minute => true do 

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

		context " -- travel search -- " do 

			it " -- finds requirements from categories a, b at the nearest location, free for time taken to travel between that location and given point. -- ", :minute_agg do 

				Auth.configuration.location_class.constantize.delete_all

				json_defintion = JSON.parse(IO.read("/home/bhargav/Github/auth/spec/test_json_assemblies/locations/2.json"))

				location_hashes = json_defintion["locations"]

				
				locations = location_hashes.map{|c|
					c = Auth.configuration.location_class.constantize.new(c)
					expect(c.save).to be_truthy
					c
				}

				options = {:speed => 20000, :coordinates => {:lat => 27.45, :lng => 58.22}, :within_radius => 10000, :categories => ["a","b","c"], :minute_ranges => [[0,100]]}

				response = Auth.configuration.location_class.constantize.loc(options)

				total_results = 0
				expected_result_minutes_in_asc_order = [1,2,3]
				response.each do |res|
					expect(res["locations"].size).to eq(2)
					expect(res["_id"]).to eq(expected_result_minutes_in_asc_order[total_results])
					total_results+=1
				end
				expect(total_results).to eq(3)

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
				expected_result_minutes_in_asc_order = [1,2,3]
				response.each do |res|
					puts JSON.pretty_generate(res)
					expect(res["locations"].size).to eq(1)
					expect(res["_id"]).to eq(expected_result_minutes_in_asc_order[total_results])
					total_results+=1
				end
				expect(total_results).to eq(3)



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


				expect(total_results).to eq(3)

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
					#puts JSON.pretty_generate(res)
					expect(res["locations"].size).to eq(1)
					total_results+=1
				end			


				expect(total_results).to eq(3)

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
					#puts JSON.pretty_generate(res)
					expect(res["locations"].size).to eq(1)
					total_results+=1
				end			


				expect(total_results).to eq(0)


			end


		end

		context " -- chain queries -- ", :chain_queries => true do 

			it " -- stores the results of each query in an ordered hash -- " do 

				## the first query returns stuff starting from minute 10 -> 3000
				## second query has a range for each of these minutes.
				## so here we query start 
				## 10(12 ->> 200).....(3012 ->> 3200)
				## so basically query for next thing will be the 
				## from 12 -> 3200
				## now if whatever we find is say 222
				## what would this correspond to?
				## how to directly get that?
				## so that we look only there, and don't have to iterate.
				## is it easier to repeat the query?
				## that is , it will already be in ram, at least some of it, and it prevents bloating.
				## so what are you saying --> basically change the start range for the first query, to be more than whatever we can safely exclude/
				## so suppose the min difference and max difference are known.
				## max difference is known,
				## so minus that from it -> you will get 22
				## so it has to be somthing more than 22
				## so we want everything more than 22.
				## but we also know less than.
				## for eg we have found something at 222.
				## so what is the latest at which it can exist.
				## it has to be 2 minutes
				## so 220
				## basically start range is
				## whatever is the first thing you found - 
				## problem with this is that it may not exist.
				## if the next one was at 
				## how to know for sure where it exists.
				## and extrapolate back n times.
				## the only way is to keep the current results in memory and query again for the earlier results.
				## for something that starts at 
				## will be better to search in memory.
				## iterate the array ?
				## or search for something of that amount.
				## how to 
				## so for each minute found, will have to find something within 200 of this ->
				## basically is this - 200 present or not.
				## so basically we have to do bsearch for the previous minute.
				## so for each of the things found, we need to check the earlier array.
				## and later on we will query if required to change.
				## so we want to keep the minutes from the earlier array, and also the current array
				## basically that is the issue on the whole
				## the problem is that if there are different cart_items.
				## we do a query so we will have to store for every different cart item.
				## which is okay.
				## so how to structure this ?
				## best place to store is the query results.
				## so inside the step we have thes

			end


			

		end

		context " -- mark static requirements -- " do 

		end


		context " -- batch options -- " do 

		end

	end

end

=begin
			it " -- agg on large location number -- ", :lagg => true do 

				response = Auth.configuration.location_class.constantize.loc

				response.each do |res|
					puts JSON.pretty_generate(res)
				end				

			end

			it " -- large location number of locations -- ", :bulk => true do 

				Auth.configuration.location_class.constantize.delete_all

				## create 100 locations
				## for each location create for 100 days
				## for each day
				## let us also create 50 entities per location.
				## and create an antry for it for a variable amount of time inside the minutes.
				r = Random.new
				10.times do |location_count|
					1.times do |day_count|
						location = Auth.configuration.location_class.constantize.new
						## we will create a random location
						location.geom = [58.22,27.45]
						location.day_id = day_count
						1440.times do |minute_count|
							m = Auth.configuration.minute_class.constantize.new
							m.minute = minute_count
							100.times do |entity_count|
								e = Auth.configuration.entity_class.constantize.new
								e.booked = false
								e.duration = [0,rand(10000..36000)]
								e.category = entity_count.to_s
								m.entities << e 
								m.minimum_entity_duration = 10000
								#puts "loaded entity :#{entity_count}"
							end
							location.minutes << m
							#puts "loaded minute: #{minute_count}"
						end
						puts "saving location #{location_count} on day id : #{day_count}"
						expect(location.save).to be_truthy
					end
				end

			end
=end

=begin
		context " -- search for multiple requirements within a certain distance of a location [NOT WORKING AND IS NO LONGER USED] -- ", :discontinued => true do 

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

				## now we should be able to do this shit.

			end

			it " -- searches for locations within a given km radius of certain coordinates, that have all specified requirements, which are also not booked. -- ", :co_entity_search => true do 


				json_defintion = JSON.parse(IO.read("/home/bhargav/Github/auth/spec/test_json_assemblies/locations/1.json"))


				location_hashes = json_defintion["locations"]


				## how are we going to do a nearest search ?
				locations = location_hashes.map{|c|
					c = Auth.configuration.location_class.constantize.new(c)
					#c.tlocations.each do |tlocation|
					#	puts tlocation.dogs.to_s
					#end
					expect(c.save).to be_truthy
				}				

				## we want to perform an elematch on a tlocation for any of the categories.
				## so we choose the first one.
				## and that should have acceptable overlap with the other categories.
				## now
				response = Auth.configuration.location_class.constantize.find_nearest_free_requirement_categories({:lat => 27.45 , :lng => 58.22},100000,["1","1"],[1,10],25)

				#puts response.count

				response.each do |result|
					puts JSON.pretty_generate(result)
				end
				

			end

			it " -- try denovo creation -- ", :deno => true do 

				dog = Auth::Workflow::Dog.new
				dog.overlap_duration = 10

				tlocation = Auth::Workflow::Tlocation.new
				tlocation.start_time = 20

				tlocation.dogs << dog

				l = Auth::Workflow::Location.new
				l.tlocations << tlocation
				l.tlocations << Auth::Workflow::Tlocation.new(:start_time => 500)
				l.geom = [23,23]

				expect(l.save).to be_truthy

				response = Auth.configuration.location_class.constantize.find_nearest_free_requirement_categories({:lat => 23 , :lng => 23},100,["1","1a"],[1,10],25)

				response.each do |res|
					puts JSON.pretty_generate(res)
				end
				#response = Auth.configuration.location_class.constantize.find_nearest_free_requirement_categories({:lat => 27.45 , :lng => 58.23},100,["1","1a"],[1,10],25)				

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
=end