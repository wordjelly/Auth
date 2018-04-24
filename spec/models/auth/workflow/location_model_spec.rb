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

			it " -- finds requirements from categories a, b at the nearest location, free for time taken to travel between that location and given point. -- ", :minute_agg do 

				Auth.configuration.location_class.constantize.delete_all

				json_defintion = JSON.parse(IO.read("/home/bhargav/Github/auth/spec/test_json_assemblies/locations/2.json"))

				location_hashes = json_defintion["locations"]

				## how are we going to do a nearest search ?
				locations = location_hashes.map{|c|
					c = Auth.configuration.location_class.constantize.new(c)
					expect(c.save).to be_truthy
					c
				}

				## uses the default values as described in the function.
				response = Auth.configuration.location_class.constantize.loc

				response.each do |res|
					puts JSON.pretty_generate(res)
				end

			end

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

		end

	end

end