require 'rails_helper'

RSpec.describe Auth::Transaction::EventHolder, type: :model, :events => true do
  		
	context " -- basic functions -- " do 
		
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


		context " -- basic definitions -- " do 

			before(:all) do 
				## create three products
				@products = create_products(3,@u,@admin)
				## create an sop applicable to the first two products.
				@sop = create_empty_sop
				@sop.applicable_to_product_ids = @products[0..1].map{|c| c = c.id.to_s}
				## now 
				@stage = create_empty_stage
				@stage.sops << @sop
				## a
				@assembly = create_empty_assembly
				@assembly.stages << @stage
				@assembly.save

				Auth::Transaction::EventHolder.delete_all

			end

			it " -- creates an event holder with a single event --  " do 

				## now we want to create an event holder
				## and to its events we want to add the first event.
				## then we want to process that event.
				event_holder = Auth::Transaction::EventHolder.new
				event = Auth::Transaction::Event.new
				event.method_to_call = "clone_to_add_cart_items"
				event.object_class = Auth.configuration.assembly_class
				## first lets just test creation.
				event_holder.events << event

				event.valid?

				#puts "event validation errors."
				#puts event.errors.full_messages.to_s

				res = event_holder.save

				#puts event_holder.errors.full_messages.to_s

				expect(res).to be_truthy


			end

			it " -- processes the events -- " do 

				event_holder = Auth::Transaction::EventHolder.new
				event = Auth::Transaction::Event.new
				event.method_to_call = "clone_to_add_cart_items"
				event.object_class = Auth.configuration.assembly_class
				event.object_id = @assembly.id.to_s
				event.arguments = {:product_id => @products.map{|c| c = c.id.to_s}}
				## first lets just test creation.
				event_holder.events << event
				expect(event_holder.save).to be_truthy

				event_holder.process

				## what should happen ? it should create a 
				## it should commit a new event.
				## and mark this event as completed.
				event_holder = Auth::Transaction::EventHolder.find(event_holder.id)

				expect(event_holder.events[0].statuses[1].condition).to eq("COMPLETED")
				expect(event_holder.events.count).to eq(2)
				expect(event_holder.events[0].statuses.count).to eq(2)
				

			end

			

		
		end

		context " -- aborts if  -- " do 

			it " --  any event is processing or failed -- " do 

			end

			it " -- an event object could not be found -- " do 

			end

			it " -- a commit failed to mark an event as completed, and the event was not already marked as completed -- " do 


			end


		end

	end
	

end
