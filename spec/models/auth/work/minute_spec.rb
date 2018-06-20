require 'rails_helper'
RSpec.describe Auth::Shopping::Product, type: :model, :minute_model => true do

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
			clean_all_work_related_classes
		end

		it " -- adds the entity types and counts to the minutes -- ", :update_minute_entities => true do 

			### CREATING PRODUCTS AND CYCLES
			product = Auth.configuration.product_class.constantize.new
			product.resource_id = @admin.id.to_s
            product.resource_class = @admin.class.name
            product.price = 10.00
            product.signed_in_resource = @admin
            
            cycle = Auth::Work::Cycle.new
            cycle.id = "first_cycle"
            cycle.duration = 10
            cycle.time_to_next_cycle = 20
            cycle.requirements = {
            	:person_trained_on_em_200 => 1
            }
            product.cycles << cycle

            product.save


            cycle = Auth::Work::Cycle.new
            cycle.id = "second_cycle"
            cycle.duration = 10
            cycle.time_to_next_cycle = 20
            cycle.requirements = {
            	:person_trained_on_em_200 => 1
            }
            product.cycles << cycle

            product.save


            cycle = Auth::Work::Cycle.new
            cycle.duration = 10
            cycle.id = "third_cycle"
            cycle.time_to_next_cycle = 20
            cycle.requirements = {
            	:person_trained_on_em_200 => 1,
            	:em_200 => 1
            }
            product.cycles << cycle
            
            

            u = User.new(attributes_for(:user_confirmed))
	        u.save
	        c = Auth::Client.new(:resource_id => @u.id, :api_key => "test", :app_ids => ["testappid"])
	        c.redirect_urls = ["http://www.google.com"]
	        c.versioned_create
	        u.client_authentication["testappid"] = "testestoken"
	        u.cycle_types = {:person_trained_on_em_200 => true}
		    expect(u.save).to be_truthy

		    

		    ## now the next thing is the entity
		    e = Auth::Work::Entity.new
		    e.cycle_types = {:em_200 => true}
		    e.save

		    e1 = Auth::Work::Entity.new
		    e1.cycle_types = {:em_200 => true}
		    e1.save
		    

		    ## now we have to create schedules
		    ## this one is for the user.
		    schedule = Auth::Work::Schedule.new
		    schedule.start_time = Time.new(2010,05,17)
		    schedule.end_time = Time.new(2012,07,9)
		    schedule.for_object_id = u.id.to_s
		    schedule.for_object_class = u.class.name.to_s
		    schedule.can_do_cycles = [product.cycles.first.id.to_s]
		    schedule.location_id = "first_location"
		    schedule.save


		    ## now one for the entity
			schedule = Auth::Work::Schedule.new
		    schedule.start_time = Time.new(2010,05,17)
		    schedule.end_time = Time.new(2012,07,9)
		    schedule.for_object_id = e.id.to_s
		    schedule.for_object_class = e.class.name.to_s
		    schedule.can_do_cycles = [product.cycles.first.id.to_s]
		    schedule.location_id = "first_location"
		    schedule.save

		    schedule = Auth::Work::Schedule.new
		    schedule.start_time = Time.new(2010,05,17)
		    schedule.end_time = Time.new(2012,07,9)
		    schedule.for_object_id = e1.id.to_s
		    schedule.for_object_class = e1.class.name.to_s
		    schedule.can_do_cycles = [product.cycles.first.id.to_s]
		    schedule.location_id = "first_location"
		    schedule.save		    

		    ## add the location
		    l = Auth.configuration.location_class.constantize.new
		    l.id = "first_location"
		    l.save
		    #puts l.attributes.to_s
		    ## so for the minutes, they are going to be the first and second minute in the duration of the schedules
		    minutes = {}
		    first_minute = Auth::Work::Minute.new
		    first_minute.time = Time.new(2011,05,5,10,12,0)
		    minutes[first_minute.time.to_i] = first_minute

		    ## and now the second minute
			second_minute = Auth::Work::Minute.new
		    second_minute.time = Time.new(2011,05,5,10,13,0)
		    minutes[second_minute.time.to_i] = second_minute

		    ## the minutes have not yet been saved.

		    returned_minutes = Auth.configuration.product_class.constantize.schedule_cycles(minutes,"first_location")

  			## now each minute ?
  			returned_minutes.keys.each do |time|
  				minute = returned_minutes[time]
  				minute.update_entity_types
  				expect(minute.entity_types["em_200"]).to eq(2)
  				expect(minute.entity_types["person_trained_on_em_200"]).to eq(1)
  			end

  			

		end

		it " -- finds the affected cycles -- " do 

			start_minute = Time.new(2012,05,05,10,10,0).to_i
			5.times do |n|
				minute = Auth::Work::Minute.new
				minute.time = start_minute
				2.times do |c|
					cycle = Auth::Work::Cycle.new
					cycle.start_time = minute.time.to_i
					cycle.duration = 10
					cycle.end_time = cycle.start_time + cycle.duration
					cycle.requirements = {
		            	:person_trained_on_em_200 => 1,
		            	:em_200 => 1
		            }
		            cycle.workers_available = ["first_worker","second_worker"]
		            cycle.entities_available = ["first_entity","second_entity"]
		            minute.cycles << cycle
				end
				minute.save
				start_minute = start_minute + 60.seconds
			end

			## now we have 5 minutes, each with 2 cycles.
			## now lets search for the affected cycles.
			## we will give a minute range that encomapsses the last three minutes.
			affected_minutes = Auth::Work::Minute.get_affected_minutes(Time.new(2012,05,05,10,13,0).to_i,Time.new(2012,05,05,10,16,0).to_i,["first_worker"],["second_entity"])

			## so first of all does it touch the correct cycels ?
			total_affected_cycles = 0
			affected_minutes.each do |minute|
				total_affected_cycles+= minute.cycles.size
			end
			expect(total_affected_cycles).to eq(4)

		end

		it " -- updates affected cycles part 1 -- " do 

			start_minute = Time.new(2012,05,05,10,10,0).to_i
			5.times do |n|
				minute = Auth::Work::Minute.new
				minute.time = start_minute
				2.times do |c|
					cycle = Auth::Work::Cycle.new
					cycle.start_time = minute.time.to_i
					cycle.duration = 10
					cycle.end_time = cycle.start_time + cycle.duration
					cycle.requirements = {
		            	:person_trained_on_em_200 => 1,
		            	:em_200 => 1
		            }
		            cycle.workers_available = ["first_worker","second_worker"]
		            cycle.entities_available = ["first_entity","second_entity"]
		            minute.cycles << cycle
				end
				minute.save
				start_minute = start_minute + 60.seconds
			end

			## now we have 5 minutes, each with 2 cycles.
			## now lets search for the affected cycles.
			## we will give a minute range that encomapsses the last three minutes.
			affected_minutes = Auth::Work::Minute.get_affected_minutes(Time.new(2012,05,05,10,13,0).to_i,Time.new(2012,05,05,10,16,0).to_i,["first_worker"],["second_entity"])


			updated_minutes = Auth::Work::Minute.update_cycles(affected_minutes,["first_worker"],["second_entity"])


			updated_minutes.uniq!

			updated_minutes.each do |u_min|
				u_min.cycles.each do |cycle|
					puts cycle.attributes.to_s
				end
			end

			expect(updated_minutes.size).to eq(affected_minutes.size)
			## okay so what is the expectation here exactly
			## what should this method return ?

		end

		it " -- updates the cycle chains of all the affected cycles -- " do 
			## okay so i forgot to add the cycle chains here.
			## 
			start_minute = Time.new(2012,05,05,10,10,0).to_i
			## how to add cycle chains. ?
			## we can just add random cycles that have already been added.
			cycles_to_minute_hash = {}
			5.times do |n|
				minute = Auth::Work::Minute.new
				minute.time = start_minute
				cycles_to_minute_hash[minute.time.to_i] = []

				2.times do |c|
					cycle = Auth::Work::Cycle.new
					cycle.start_time = minute.time.to_i
					cycle.duration = 10
					cycle.end_time = cycle.start_time + cycle.duration
					cycle.requirements = {
		            	:person_trained_on_em_200 => 1,
		            	:em_200 => 1
		            }
		            cycle.workers_available = ["first_worker","second_worker"]
		            cycle.entities_available = ["first_entity","second_entity"]

		            ## all the cycles of the same index done before.
		            cycles_to_minute_hash.keys.each do |k|
		            	if k < minute.time.to_i
		            		cycle.cycle_chain << cycles_to_minute_hash[k][c].id.to_s
		            	end
		            end
		            minute.cycles << cycle
		            cycles_to_minute_hash[minute.time.to_i] << cycle
				end
				minute.save
				start_minute = start_minute + 60.seconds
			end

			## now we have 5 minutes, each with 2 cycles.
			## now lets search for the affected cycles.
			## we will give a minute range that encomapsses the last three minutes.
			affected_minutes = Auth::Work::Minute.get_affected_minutes(Time.new(2012,05,05,10,13,0).to_i,Time.new(2012,05,05,10,16,0).to_i,["first_worker"],["second_entity"])

			cycles_to_pull = Auth::Work::Minute.update_cycle_chains(affected_minutes)

			response = Auth::Work::Minute.collection.aggregate([
				{
					"$match" => {
						"cycles._id" => {
							"$in" => cycles_to_pull
						}
					}
				}
			])
			response = response.to_a
			expect(response).to be_empty

		end

		it " -- finds the nearest minute to schedule the job -- " do 

			## so we have three products that need to be done
			## product 1 -> starts with cycle a : {worker_type_a => 1, entity_type_a => 1, :capacity => }
			## product 2 -> starts with cycle b : {worker_type_a => 1, enttity_type_a => 1} : this could 
			## product 3 -> starts with cycle c : {worker_type_b => 1}

			## what if two products, need the same start cycle ?
			## then they have to be fused, just bumping the capacity.
			## so that will be the first step.
			## a cycle runs on a certain set of samples.
			## so basically we are looking for something with a minimum capacity of say 10.
			## why not complicate this with redis
			## wouldn't that be really fun.
			## subtract total worker types found, from the maximum needed, 
			## this not practical by any length.
			## i need to structure the cycles like that.
			## worker type a, worker type b, worker type c
			## project a -> 
			## so first of all have to build this.


			## so in order to do this job, we need 2 workers of type a, and one of type b.
			## the minimum's are to be found and defined first.
			## so they will be the individual start cycle clauses.
			## now the search is done for the bare minimum's
			## 

		end
		
	end

end

## rough plan
## 10 -> 20 : finish the cycles, and then decide what kind of ui it should have, test object + integration with shopping cart + notifications + video / image integration with cycle + bar code.
## 20 -> 30 : b2b + collection boy interface + location interface + apis for the symptoms, videos, image + 
## 20 -> 30 : cycle ui + symptom test
## 1 -> 7 : add all the cycles and steps into the 
