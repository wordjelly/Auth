require 'rails_helper'
RSpec.describe Auth::Workflow::Sop, type: :model, :sop_model => true do

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

		context " -- create order flow -- " do 

			it " -- returns empty response if no sop's are found -- " do 
				
				cart_items_and_assembly = create_cart_items_assembly_sops_with_product_ids(@u,2,false)
				cart_items = cart_items_and_assembly[:cart_items]
				assembly = cart_items_and_assembly[:assembly]
				## it should have created two cart items.
				## fire the clone event, expect it to return the array of events searching for those sop's.
				## now clone with all the product ids in the arguments.
				options = {}
				options[:product_ids] = cart_items.map{|c| c = c.product_id.to_s}
				options[:cart_item_ids] = cart_items.map{|c| c = c.id.to_s}
				events = assembly.clone_to_add_cart_items(options)
				
				## so we want to call process on each of these events.
				events.each do |event|
					expect(event.process).to be_empty
				end

			end

			it " -- creates a series of events to create the order. -- " do 
				cart_items_and_assembly = create_cart_items_assembly_sops_with_product_ids(@u,2)
				cart_items = cart_items_and_assembly[:cart_items]
				assembly = cart_items_and_assembly[:assembly]
				options = {}
				options[:product_ids] = cart_items.map{|c| c = c.product_id.to_s}
				options[:cart_item_ids] = cart_items.map{|c| c = c.id.to_s}
				search_sop_events = assembly.clone_to_add_cart_items(options)
				## there is only one such event that is created.
				## so we want to call process on each of these events.
				event = search_sop_events.first
				create_order_events = event.process
				expect(create_order_events).not_to be_empty
				create_order_events.each do |cr_or_ev|
					expect(cr_or_ev.object_id).not_to be_nil
				end

			end

			it " -- clone -> find_applicable_sop's event -> returns an array of applicable_sops -> which should then launch the events for create_order_in sop -> should generate mark requirement events. -- ", :latest => true do 

				## setup is 
				cart_items_and_assembly = create_cart_items_assembly_sops_with_product_ids(@u,2)
				cart_items = cart_items_and_assembly[:cart_items]
				assembly = cart_items_and_assembly[:assembly]
				
				products = [Auth.configuration.product_class.constantize.new,Auth.configuration.product_class.constantize.new]
				products.map{|c|
					c.resource_id = @admin.id.to_s
					c.resource_class = @admin.class.to_s
					c.price = 30
					expect(c.save).to be_truthy
				}
				assembly = add_steps_requirements_states_to_assembly(assembly,products)

				expect(assembly.save).to be_truthy

				options = {}
				options[:product_ids] = cart_items.map{|c| c = c.product_id.to_s}
				options[:cart_item_ids] = cart_items.map{|c| c = c.id.to_s}
				search_sop_event = assembly.clone_to_add_cart_items(options).first
				
				create_order_events = search_sop_event.process

				## now the create_order events, will create the order
				## and then will generate the schedule_order event

				create_order_events.each do |crod|
					schedule_order_events = crod.process
					schedule_order_events.each do |sch|
						expect(sch.process).not_to be_nil
					end
				end

			end


			context " -- schedule order --  " do 

				context " -- transferring location information -- ", :transfer_time_location => true do 

					it " -- assigns the location information from the first cart item to the step if the step location information is blank -- " do 

						options = {}

						products = [Auth.configuration.product_class.constantize.new,Auth.configuration.product_class.constantize.new]

						products.map{|c|
							c.resource_id = @admin.id.to_s
							c.resource_class = @admin.class.to_s
							c.price = 30
							expect(c.save).to be_truthy
						}

						products_for_requirements = [Auth.configuration.product_class.constantize.new,Auth.configuration.product_class.constantize.new]

						products_for_requirements.map{|c|
							c.resource_id = @admin.id.to_s
							c.resource_class = @admin.class.to_s
							c.price = 30
							expect(c.save).to be_truthy
						}

						options[:stages] = 3
						options[:sops] = 3
						options[:steps] = 3
						options[:requirements] = 3
						
						options[:products] = {products.first.id.to_s.to_sym => ["0.1","1.2","2.0"], products.last.id.to_s.to_sym => ["0.1","1.2","2.1"]}

						options[:requirements_products] = {products_for_requirements.first.id.to_s.to_sym => ["0.1.1.0","1.2.0.2","2.0.1.2"], products_for_requirements.last.id.to_s.to_sym => ["0.1.2.1","1.2.1.2","2.1.2.2"]}

						response = create_assembly_with_options(options)

						expect(response[:errors]).to be_blank

						assembly = response[:assembly]
						expect(assembly.save).to be_truthy
						assembly.master = true

						cart_items = products.map{|p|
							c = Auth.configuration.cart_item_class.constantize.new
							c.product_id = p.id.to_s
							c.location_information = {
								:within_radius => 20,
								:location_point_coordinates => [10,20]
							}
							c.resource_id = @u.id.to_s
							c.resource_class = @u.class.to_s
							c.signed_in_resource = @u
							expect(c.save).to be_truthy
							c
						}

						options = {}

						options[:product_ids] = cart_items.map{|c| c = c.product_id.to_s}
						
						options[:cart_item_ids] = cart_items.map{|c| c = c.id.to_s}

						search_sop_event = assembly.clone_to_add_cart_items(options)

						expect(search_sop_event).not_to be_blank

						create_order_events = search_sop_event.first.process

						## now the create_order events, will create the order
						## and then will generate the schedule_order event

						create_order_events.each do |crod|
							schedule_order_events = crod.process
							schedule_order_events.each do |sch|
								expect(sch.process).not_to be_nil
							end
						end				

					end

					it "-- passes on step information from a previous step if the step does not have its own location information -- " do 

					end

					it " -- passes step location information to requirement if the requirement doesnt have its own location information -- " do 

					end

				end

				context " -- transferring time information -- " do 

				end	


				context " -- resolve --  " do 

				end


				context " -- duration -- " do 

				end


				context " -- location queries -- " do 


				end	

				context " -- case scenarios -- " do 

					context " -- stool collection scenario -- " do 

					end

					context " -- t3,t4,tsh scenario -- " do 

					end

					context " -- dsdNa to metropolis scenario -- " do 

					end


					context " -- 24 hr urine for protein scenario -- " do 

					end


					context " -- stool + 24 hr urine scenario -- " do 

					end

				end

		 	end
			
		end

	end

end