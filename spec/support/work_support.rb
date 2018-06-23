module WorkSupport
	def clean_all_work_related_classes
			Auth::Shopping::Product.delete_all
			Auth.configuration.location_class.constantize.delete_all
			Auth.configuration.user_class.constantize.delete_all
			Auth::Work::Schedule.delete_all
			Auth::Work::Minute.delete_all
	end

	
	## creates three cycles
	## creates two minutes
	## adds the cycles to the minutes
	## saves the minutes
	## @return[Hash] {epoch => minute_object}
	def setup_minutes_with_cycles

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
        cycle.cycle_type = "a"
        cycle.requirements = {
        	:person_trained_on_em_200 => 1
        }
        product.cycles << cycle

        product.save


        cycle = Auth::Work::Cycle.new
        cycle.id = "second_cycle"
        cycle.duration = 10
        cycle.time_to_next_cycle = 20
        cycle.cycle_type = "b"
        cycle.requirements = {
        	:person_trained_on_em_200 => 1
        }
        product.cycles << cycle

        product.save


        cycle = Auth::Work::Cycle.new
        cycle.duration = 10
        cycle.id = "third_cycle"
        cycle.time_to_next_cycle = 20
        cycle.cycle_type = "c"
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

	    	
	   	returned_minutes = Auth.configuration.product_class.constantize.schedule_cycles(minutes,"first_location")

	   	returned_minutes.keys.each do |epoch|
	   		expect(returned_minutes[epoch].save).to be_truthy
	   	end

	   	returned_minutes
	end

end
RSpec.configure do |config|
	config.include WorkSupport, :type => :request
	config.include WorkSupport, :type => :model
end