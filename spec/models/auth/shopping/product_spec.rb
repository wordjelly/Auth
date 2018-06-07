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

		it " -- adds cycles to appropriate minutes in the schedules -- " do 

			### CREATING PRODUCTS AND CYCLES
			product = Auth.configuration.product_class.constantize.new
			product.resource_id = @admin.id.to_s
            product.resource_class = @admin.class.name
            product.price = 10.00
            product.signed_in_resource = @admin
            cycle = Auth::Work::Cycle.new
            cycle.duration = 10
            cycle.time_to_next_cycle = 20
            cycle.requirements = {
            	:person_trained_on_em_200 => 1,
            	:em_200 => 1
            }
            product.cycles << cycle
            product.save


            ## now the next thing is to make one such user and one such entity.
            u = User.new(attributes_for(:user_confirmed))
	        u.save
	        c = Auth::Client.new(:resource_id => @u.id, :api_key => "test", :app_ids => ["testappid"])
	        c.redirect_urls = ["http://www.google.com"]
	        c.versioned_create
	        u.client_authentication["testappid"] = "testestoken"
	        u.cycle_types = {:person_trained_on_em_200 => true}
		    expect(u.save).to be_truthy

		    #puts "---------------- ID OF THE SAVED USER -: #{u.id.to_s}"


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
		    first_minute.time = Time.new(2011,05,5)
		    minutes[first_minute.time.to_i] = first_minute

		    ## and now the second minute
			second_minute = Auth::Work::Minute.new
		    second_minute.time = Time.new(2011,05,6)
		    minutes[second_minute.time.to_i] = second_minute

		    ## now that we have done that, we can pass in all this and see what happens.
		    returned_minutes = Auth.configuration.product_class.constantize.schedule_cycles(minutes,"first_location")
		    expect(returned_minutes.size).to eq(2)
		    returned_minutes.keys.each do |time|
		    	expect(returned_minutes[time].cycles).not_to be_empty
		    end


		end


	end

end