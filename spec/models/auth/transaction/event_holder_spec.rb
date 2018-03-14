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
				Auth::Transaction::EventTest.delete_all

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
				expect(event_holder.status).to be_nil

			end

			it " -- marks event holder status as completed, if event count does not change -- " do 

				## lets add an event that does not produce additional events.

				## for that purpose we can create another object.
				et = Auth::Transaction::EventTest.new
				expect(et.save).to be_truthy

				event_holder = Auth::Transaction::EventHolder.new
				event = Auth::Transaction::Event.new
				event.method_to_call = "does_not_return_event"
				event.object_class = "Auth::Transaction::EventTest"
				event.object_id = et.id.to_s
				event.arguments = {}
				## first lets just test creation.
				event_holder.events << event
				expect(event_holder.save).to be_truthy

				event_holder.process

				expect(event_holder.status).to eq(1)

			end


			it " -- does not process event, if it is already processing -- " do 

				## so the first time should return that it returned as nil.
				et = Auth::Transaction::EventTest.new
				expect(et.save).to be_truthy

				event_holder = Auth::Transaction::EventHolder.new
				event = Auth::Transaction::Event.new
				event.method_to_call = "returns_nil"
				event.object_class = "Auth::Transaction::EventTest"
				event.object_id = et.id.to_s
				event.arguments = {}
				## first lets just test creation.
				event_holder.events << event
				expect(event_holder.save).to be_truthy

				expect(event_holder.process.abort_function).to eq("event_processing_returned_nil:#{event.id.to_s}")


				expect(event_holder.process.abort_function).to eq("processing:#{event.id.to_s}")

				

			end


			it " -- processes event if , its processing has exceeded the period -- ", :process_issue => true do 

				## so how to simulate this eventuality
				## so we have to manually set the last status of the last event, as more than 30 mins prior.
				et = Auth::Transaction::EventTest.new
				expect(et.save).to be_truthy

				event_holder = Auth::Transaction::EventHolder.new
				event = Auth::Transaction::Event.new
				event.method_to_call = "returns_nil"
				event.object_class = "Auth::Transaction::EventTest"
				event.object_id = et.id.to_s
				event.arguments = {}
				## first lets just test creation.
				event_holder.events << event
				expect(event_holder.save).to be_truthy

				expect(event_holder.process.abort_function).to eq("event_processing_returned_nil:#{event.id.to_s}")				

				## now set that status.
				event_holder = Auth::Transaction::EventHolder.find(event_holder.id)
				puts JSON.pretty_generate(event_holder.attributes)
				
				event_holder.events[-1].statuses[-1].updated_at = Time.now - 1.day

				## it is saying could not mark as processing here.

				expect(event_holder.save).to be_truthy

				## now run it again.

				## and what should happen, again should come out at nil..

				expect(event_holder.process.abort_function).to eq("event_processing_returned_nil:#{event.id.to_s}")					


			end

			it " -- skips the event if the event has completed -- " do 

				
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
				expect(event_holder.status).to be_nil




				## now suppose we call proces again,
				## we don't want it to have completed.
				event_holder = Auth::Transaction::EventHolder.find(event_holder.id)

				## call process on it.
				## 
				event_holder.process
				
				expect(event_holder.events_ignored_since_already_completed.first.id.to_s).to eq(event.id.to_s)

			end


			context " -- mark event as processing -- " do 
				
				## there's no way to test the condition, wherein , a status is added just before the find_and_update call is made, and even that one is still processing.
				## or is there a way
				## 
				it " -- failure to mark event as processing for any reason, will cause the whole thing to abort -- " do 

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
					expect(event_holder.status).to be_nil




					## now suppose we call proces again,
					## we don't want it to have completed.
					event_holder = Auth::Transaction::EventHolder.find(event_holder.id)

					## now if we call process.
					## then this should happen.

					## make it so that another status is inserted, with processing, only, but then the given status count will be different.
					Auth::Transaction::EventHolder.class_eval do  

						def before_mark_event_as_processing(ev)
							## push an additinal status.
							event_holder = Auth::Transaction::EventHolder.find(self.id.to_s)
							event_holder.events[ev.event_index].statuses << Auth::Transaction::Status.new(:condition => "PROCESSING")
							puts "save result:"
							res = event_holder.save
							puts res.to_s						
						end

					end


					event_holder.process

					expect(event_holder.abort_function).to eq	("could_not_mark_as_processing:#{event_holder.events[-1].id.to_s}")

					## reset the class eval.
					Auth::Transaction::EventHolder.class_eval do  

						def before_mark_event_as_processing(ev)
												
						end

					end


				end

								

			end


			context " -- commit new events -- " do 

				it " -- something else has already committed the new events -- " do 

					event_holder = Auth::Transaction::EventHolder.new
					event = Auth::Transaction::Event.new
					event.method_to_call = "clone_to_add_cart_items"
					event.object_class = Auth.configuration.assembly_class
					event.object_id = @assembly.id.to_s
					event.arguments = {:product_id => @products.map{|c| c = c.id.to_s}}
					## first lets just test creation.
					event_holder.events << event
					expect(event_holder.save).to be_truthy

					## before doing, this mutate the before_commit_new_events method, so that 

					Auth::Transaction::EventHolder.class_eval do  

						def before_commit_new_events(latest_event_holder,events,ev)
							## push an additinal status.
							event_holder = Auth::Transaction::EventHolder.find(self.id.to_s)
							
							event_holder.events << events
							event_holder.events.flatten!
							
							res = event_holder.save
							puts res.to_s				
						end

					end

					event_holder.process

					## what we want returned is that the 
					expect(event_holder.abort_function).to eq("could not commit new events or mark event as completed:#{event.id.to_s}")

					Auth::Transaction::EventHolder.class_eval do  

						def before_commit_new_events(latest_event_holder,events,ev)
										
						end

					end

				end


			end


			context " -- marks event as completed -- " do 

				it " -- something else has already marked the event as completed -- " do 	

					event_holder = Auth::Transaction::EventHolder.new
					event = Auth::Transaction::Event.new
					event.method_to_call = "clone_to_add_cart_items"
					event.object_class = Auth.configuration.assembly_class
					event.object_id = @assembly.id.to_s
					event.arguments = {:product_id => @products.map{|c| c = c.id.to_s}}
					## first lets just test creation.
					event_holder.events << event
					expect(event_holder.save).to be_truthy


					Auth::Transaction::EventHolder.class_eval do 




						def before_mark_existing_event_as_complete(latest_event_holder,events,ev)

							event_holder = Auth::Transaction::EventHolder.find(self.id.to_s)
							
							event_holder.events[ev.event_index].statuses << Auth::Transaction::Status.new(:condition => "COMPLETED")
							
							res = event_holder.save
									

						end

					end

					event_holder.process

					expect(event_holder.abort_function).to eq("could not commit new events or mark event as completed:#{event.id.to_s}")

					Auth::Transaction::EventHolder.class_eval do 




						def before_mark_existing_event_as_complete(latest_event_holder,events,ev)

							
									

						end

					end


				end

			end


			
		
		end

	end
	

end
