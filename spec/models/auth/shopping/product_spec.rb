require 'rails_helper'
RSpec.describe Auth::Shopping::Product, type: :model, :product_model => true do

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

		## how will it find the affected cycles ?
		## 

		it " -- adds cycles to appropriate minutes in the schedules, adds rolling minutes, and cycle chains -- " do 

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

		    returned_minutes = Auth.configuration.product_class.constantize.schedule_cycles(minutes,"first_location")

		    ## if there are 3 cycles that are applicable to each minute, then the first minute should have 6 cycles and the second should have 3 cycles
		    ## as far as the chain is concerned.
		    ## if we consider the first minute.

		    expect(returned_minutes.size).to eq(2)
					
			## expect the first minute to have 6 cycles
			## expect the second minute to have 3 cycles

			## how to find the expected ids ?
			## 

			expect(returned_minutes.values.first.cycles.size).to eq(6)
			expect(returned_minutes.values.last.cycles.size).to eq(3)

		    returned_minutes.keys.each do |time|
		    	
		    	returned_minutes[time].cycles.each do |cycle|

		    		if cycle.id == "first_cycle"
		    			expect(cycle.cycle_chain).to be_empty
		    		elsif cycle.id == "second_cycle"
		    			expect(cycle.cycle_chain).to eq(["first_cycle"])
		    		elsif cycle.id == "third_cycle"
		    			expect(cycle.cycle_chain).to eq(["first_cycle","second_cycle"])
		    		end
		    	end
		    end
		end

	end

end