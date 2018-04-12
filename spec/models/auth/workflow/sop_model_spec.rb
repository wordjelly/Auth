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

			before(:example) do 
				Auth::Workflow::Assembly.delete_all
				Auth::Workflow::Location.delete_all
			end

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
						

						first_product_applicable_to_sops = ["0.1","1.2","2.0"]

						second_product_applicable_to_sops =  ["0.1","1.2","2.1"]


						expected_sop_addresses_for_creating_orders = (first_product_applicable_to_sops + second_product_applicable_to_sops).uniq

						options[:products] = {products.first.id.to_s.to_sym => first_product_applicable_to_sops, products.last.id.to_s.to_sym => second_product_applicable_to_sops}

						options[:requirements_products] = {products_for_requirements.first.id.to_s.to_sym => ["0.1.1.0","1.2.0.2","2.0.1.2"], products_for_requirements.last.id.to_s.to_sym => ["0.1.2.1","1.2.1.2","2.1.2.2"]}

						response = create_assembly_with_options(options)

						expect(response[:errors]).to be_blank

						assembly = response[:assembly]
						expect(assembly.save).to be_truthy
						assembly.master = true

						cart_items = products.map{|p|
							c = Auth.configuration.cart_item_class.constantize.new
							c.product_id = p.id.to_s

							## suppose that we want to modify location information for 
							## 0.1.1
							## 2.0.2
							
							c.resource_id = @u.id.to_s
							c.resource_class = @u.class.to_s
							c.signed_in_resource = @u
							c.location_information = {
								"stages:0:sops:1:steps:1" => {
									:within_radius => 20,
									:location_point_coordinates => [10,20]
								},
								"stages:2:sops:0:steps:2" => {
									:within_radius => 20,
									:location_point_coordinates => [10,20]	
								}
							}
							expect(c.save).to be_truthy
							c
						}

						options = {}
						options[:product_ids] = cart_items.map{|c| c = c.product_id.to_s}
						options[:cart_item_ids] = cart_items.map{|c| c = c.id.to_s}
						search_sop_event = assembly.clone_to_add_cart_items(options)
						expect(search_sop_event).not_to be_blank
						create_order_events = search_sop_event.first.process
						expect(create_order_events.size).to eq(4)
						
						
						create_order_events.each do |crod|

							crod_address = crod.arguments[:stage_index].to_s + "." + crod.arguments[:sop_index].to_s

							expected_sop_addresses_for_creating_orders.delete(crod_address)


							schedule_order_events = crod.process
							
							schedule_order_events.each do |sch|
								
								next_event = sch.process.first
								
								next_event.arguments[:steps].each do |step|
									
									## these are only going to be for applicable sops.
									first_cart_item_location_information = cart_items.first.location_information

									address = "stages:#{step.stage_index}:sops:#{step.sop_index}:steps:#{step.step_index}"


									if first_cart_item_location_information[address]

										puts "the address is:#{address}"

										expect(step.location_information[:within_radius]).to eq(first_cart_item_location_information[address][:within_radius])
										expect(step.location_information[:location_point_coordinates]).to eq(first_cart_item_location_information[address][:location_point_coordinates])
									end

								end	
							end
						

						end		

						## we delete the addresses that are found, and so this should finally be 0.
						expect(expected_sop_addresses_for_creating_orders.size).to eq(0)		

					end

					it "-- passes on location information from a previous step if the step does not have its own location information -- " do 

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
						

						first_product_applicable_to_sops = ["0.1","1.2","2.0"]

						second_product_applicable_to_sops =  ["0.1","1.2","2.1"]

						options[:products] = {products.first.id.to_s.to_sym => first_product_applicable_to_sops, products.last.id.to_s.to_sym => second_product_applicable_to_sops}

						options[:requirements_products] = {products_for_requirements.first.id.to_s.to_sym => ["0.1.1.0","1.2.0.2","2.0.1.2"], products_for_requirements.last.id.to_s.to_sym => ["0.1.2.1","1.2.1.2","2.1.2.2"]}

						response = create_assembly_with_options(options)

						expect(response[:errors]).to be_blank

						assembly = response[:assembly]
						expect(assembly.save).to be_truthy
						assembly.master = true

						## add some location information to the first step in every sop.

						cart_items = products.map{|p|
							c = Auth.configuration.cart_item_class.constantize.new
							c.product_id = p.id.to_s
							c.resource_id = @u.id.to_s
							c.resource_class = @u.class.to_s
							c.signed_in_resource = @u
							expect(c.save).to be_truthy
							c
						}

						assembly.stages.each_with_index {|stage,key|
							stage.sops.each_with_index {|sop,sop_key|


								assembly.stages[key].sops[sop_key].steps.first.location_information = {
									:within_radius => 20,
									:location_point_coordinates => [10,20]	
								}
							}
						}

						expect(assembly.save).to be_truthy

						## so now what.

						options = {}
						options[:product_ids] = cart_items.map{|c| c = c.product_id.to_s}
						options[:cart_item_ids] = cart_items.map{|c| c = c.id.to_s}
						search_sop_event = assembly.clone_to_add_cart_items(options)
						expect(search_sop_event).not_to be_blank
						create_order_events = search_sop_event.first.process
						expect(create_order_events.size).to eq(4)
						
						## now get the steps and check that all of them have the damn location information set on them.

						create_order_events.each do |crod|

							
							schedule_order_events = crod.process
							
							schedule_order_events.each do |sch|
								
								next_event = sch.process.first
								
								next_event.arguments[:steps].each_with_index {|step,index|
									
									if index > 0

										expect(step.location_information[:within_radius]).to eq(20)

										expect(step.location_information[:location_point_coordinates]).to eq([10,20])

									end	

								}
							end
						end


					end

					it " -- passes step location information to requirement if the requirement doesnt have its own location information -- ", :step_to_req => true do 

						## how to simulate this one?
						## the first requirement, let us give its own location information
						## the second one onwards should have it from the step.
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
						

						first_product_applicable_to_sops = ["0.1","1.2","2.0"]

						second_product_applicable_to_sops =  ["0.1","1.2","2.1"]

						options[:products] = {products.first.id.to_s.to_sym => first_product_applicable_to_sops, products.last.id.to_s.to_sym => second_product_applicable_to_sops}

						options[:requirements_products] = {products_for_requirements.first.id.to_s.to_sym => ["0.1.1.0","1.2.0.2","2.0.1.2"], products_for_requirements.last.id.to_s.to_sym => ["0.1.2.1","1.2.1.2","2.1.2.2"]}

						response = create_assembly_with_options(options)

						expect(response[:errors]).to be_blank

						assembly = response[:assembly]
						expect(assembly.save).to be_truthy
						assembly.master = true

						## add some location information to the first step in every sop.

						cart_items = products.map{|p|
							c = Auth.configuration.cart_item_class.constantize.new
							c.product_id = p.id.to_s
							c.resource_id = @u.id.to_s
							c.resource_class = @u.class.to_s
							c.signed_in_resource = @u
							expect(c.save).to be_truthy
							c
						}

						assembly.stages.each_with_index {|stage,key|

							stage.sops.each_with_index {|sop,sop_key|
								assembly.stages[key].sops[sop_key].steps.first.location_information = {
								:within_radius => 20,
								:location_point_coordinates => [10,20]	
								}

								sop.steps.each_with_index{|step,step_key|

									assembly.stages[key].sops[sop_key].steps[step_key].requirements.first.location_information = {
										:within_radius => 400,
										:location_point_coordinates => [40,450]
									}

									assembly.stages[key].sops[sop_key].steps[step_key].requirements.each_with_index{|rq,rq_key|

										assembly.stages[key].sops[sop_key].steps[step_key].requirements[rq_key].schedulable = true

									}

								}

							}
						}
						

						expect(assembly.save).to be_truthy

						## so now what.

						options = {}
						options[:product_ids] = cart_items.map{|c| c = c.product_id.to_s}
						options[:cart_item_ids] = cart_items.map{|c| c = c.id.to_s}
						search_sop_event = assembly.clone_to_add_cart_items(options)
						expect(search_sop_event).not_to be_blank
						create_order_events = search_sop_event.first.process
						expect(create_order_events.size).to eq(4)
						
						## now get the steps and check that all of them have the damn location information set on them.

						create_order_events.each do |crod|

							
							schedule_order_events = crod.process
							
							schedule_order_events.each do |sch|
								
								next_event = sch.process.first
								
								next_event.arguments[:steps].each_with_index {|step,index|
									
									step.requirements.each_with_index{|rq,rq_index|

										if rq_index == 0

											expect(rq.location_information[:within_radius]).to eq(400)

											expect(rq.location_information[:location_point_coordinates]).to eq([40,450])


										else

											expect(rq.location_information[:within_radius]).to eq(20)

											expect(rq.location_information[:location_point_coordinates]).to eq([10,20])

										end	

									}

								}
							end
						end


					end

				end


				context " -- transferring time information -- " do 

				end	


				context " -- location information transfer overrides -- " do 

					it " -- cart item information overrides native step information -- " do 


					end

					it " -- prev step, overrides present step information -- " do 

					end

					it " -- first step, picks up information from last step of previous sop ?  --  " do 

					end

				end

				context " -- resolve --  " do 
				
					it " -- resolves location provided location id -- ", :resolve => true do 

						locations = []

						lc = Auth::Workflow::Location.new
						lc.location = {:lat => 10.0, :lng => 15.0}
						lc.location_categories = ["hematology_station","biochemistry_station"]
						expect(lc.save).to be_truthy
						locations << lc


						lc2 = Auth::Workflow::Location.new
						lc2.location = {:lat => 10.1, :lng => 15.1}
						lc2.location_categories = ["biochemistry_station"]
						expect(lc2.save).to be_truthy
						locations << lc2

						## now we do the usual assembly creation part.	

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
						

						first_product_applicable_to_sops = ["0.1","1.2","2.0"]

						second_product_applicable_to_sops =  ["0.1","1.2","2.1"]

						options[:products] = {products.first.id.to_s.to_sym => first_product_applicable_to_sops, products.last.id.to_s.to_sym => second_product_applicable_to_sops}

						options[:requirements_products] = {products_for_requirements.first.id.to_s.to_sym => ["0.1.1.0","1.2.0.2","2.0.1.2"], products_for_requirements.last.id.to_s.to_sym => ["0.1.2.1","1.2.1.2","2.1.2.2"]}

						response = create_assembly_with_options(options)

						expect(response[:errors]).to be_blank

						assembly = response[:assembly]
						expect(assembly.save).to be_truthy
						assembly.master = true

						## add some location information to the first step in every sop.

						cart_items = products.map{|p|
							c = Auth.configuration.cart_item_class.constantize.new
							c.product_id = p.id.to_s
							c.resource_id = @u.id.to_s
							c.resource_class = @u.class.to_s
							c.signed_in_resource = @u
							expect(c.save).to be_truthy
							c
						}

						assembly.stages.each_with_index {|stage,key|
							stage.sops.each_with_index {|sop,sop_key|

								address = "#{key}.#{sop_key}"
								if (first_product_applicable_to_sops + second_product_applicable_to_sops).include? address
									puts "FOUND INCLUDE."
									## add a location id to all the steps and pass resolve to true on all of them.
									[0,1,2].each do |st_key|
										assembly.stages[key].sops[sop_key].steps[st_key].resolve = true	
										assembly.stages[key].sops[sop_key].steps[st_key].location_information[:location_id] = locations.sample.id.to_s
									end
								end 
							}
						}

						## the first thing to check is whether for each of those sops, each of the steps has been actually given a resolved id.



						## now we expect that all the resulting steps will have a location id.
						expect(assembly.save).to be_truthy

						## so now what.

						options = {}
						options[:product_ids] = cart_items.map{|c| c = c.product_id.to_s}
						options[:cart_item_ids] = cart_items.map{|c| c = c.id.to_s}
						search_sop_event = assembly.clone_to_add_cart_items(options)
						expect(search_sop_event).not_to be_blank
						create_order_events = search_sop_event.first.process
						expect(create_order_events.size).to eq(4)
						
						## now get the steps and check that all of them have the damn location information set on them.

						create_order_events.each do |crod|

							schedule_order_events = crod.process
							
							schedule_order_events.each do |sch|
								
								next_event = sch.process.first
								
								next_event.arguments[:steps].each_with_index {|step,index|
									
									expect(step.resolved_location_id).not_to be_nil

								}
							end
						end

					end

					it " -- resolves location provieded location coordinates and within radius -- " do 

						## so for this the setup is similar.


					end


					it " -- resolves location provided location coordinates, radius and categories -- " do 


					end


					it " -- resolves step location where location information is provided in the step itself -- " do 

					end

					it " -- resolves step location, where location information is transferred from the first step/previous step -- " do 

					end


					it " -- resolves step location, where the location information is passed in from the cart items -- " do 

					end			
	
				end


				context " -- duration -- " do 

				end


				context " -- location queries -- ", :location_queries => true do 

					it " -- given 20 location objects, finds the nearest one given a spherical distance -- " do 

						Auth::Workflow::Location.delete_all

						locations = []
	
						lc = Auth::Workflow::Location.new
						lc.location = {:lat => 10.0, :lng => 15.0}
						lc.location_categories = ["hematology_station","biochemistry_station"]
						expect(lc.save).to be_truthy
						locations << lc


						lc = Auth::Workflow::Location.new
						lc.location = {:lat => 10.1, :lng => 15.1}
						lc.location_categories = ["biochemistry_station"]
						expect(lc.save).to be_truthy
						locations << lc	

						
						loc = locations.last
							
						## querying within 10 miles.	
						location_query = loc.generate_location_query(loc.location,10,["biochemistry_station"])

						location_results = Auth::Workflow::Location.where(location_query)

						expect(location_results.size).to eq(2)

					end

				end	

				context " -- after one step is resolved, can use that in the next step -- " do 

				end


				context " -- build query -- " do 

				end


				context " -- do schedule update -- " do 

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