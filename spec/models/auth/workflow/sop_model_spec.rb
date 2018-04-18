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

			it " -- returns empty response if no sop's are found -- ", :refac => true do 
				
				cart_items_and_assembly = create_cart_items_assembly_sops_with_product_ids(@u,2,false)
				cart_items = cart_items_and_assembly[:cart_items]
				assembly = cart_items_and_assembly[:assembly]
				## it should have created two cart items.
				## fire the clone event, expect it to return the array of events searching for those sop's.
				## now clone with all the product ids in the arguments.
				options = {}
				options[:order] = Auth.configuration.order_class.constantize.new(:cart_item_ids => cart_items.map{|c| c = c.id.to_s}).to_json
				events = assembly.clone_to_add_cart_items(options)
				
				## so we want to call process on each of these events.
				events.each do |event|
					expect(event.process).to be_empty
				end

			end

			it " -- finds applicable sops, and creates an event that will create the order in all those sops. -- ", :refac => true do 
				cart_items_and_assembly = create_cart_items_assembly_sops_with_product_ids(@u,2)
				cart_items = cart_items_and_assembly[:cart_items]
				assembly = cart_items_and_assembly[:assembly]
				options = {}
				options[:order] = Auth.configuration.order_class.constantize.new(:cart_item_ids => cart_items.map{|c| c = c.id.to_s}).to_json
				search_sop_events = assembly.clone_to_add_cart_items(options)
				expect(search_sop_events.size).to eq(1)
				create_order_events = search_sop_events.first.process
				expect(create_order_events.size).to eq(1)
				

			end

			it " -- clone -> find applicable sops -> create the order in all those sops. -- ", :refac => true do 

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
				options[:order] = Auth.configuration.order_class.constantize.new(:cart_item_ids => cart_items.map{|c| c = c.id.to_s}).to_json
				search_sop_events = assembly.clone_to_add_cart_items(options)
				expect(search_sop_events.size).to eq(1)
				create_order_events = search_sop_events.first.process
				expect(create_order_events.size).to eq(1)
				schedule_sop_events = create_order_events.first.process
				expect(schedule_sop_events.size).to eq(1)

			end

			it " -- clone -> find applicable sops -> create the order in all those sops -> returns event to schedule all those orders -> returns empty event, with the modified sop's in the arguments. -- ", :refaca => true do 

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
				options[:order] = Auth.configuration.order_class.constantize.new(:cart_item_ids => cart_items.map{|c| c = c.id.to_s}).to_json
				search_sop_events = assembly.clone_to_add_cart_items(options)
				expect(search_sop_events.size).to eq(1)
				create_order_events = search_sop_events.first.process
				expect(create_order_events.size).to eq(1)
				schedule_sop_events = create_order_events.first.process
				expect(schedule_sop_events.size).to eq(1)
				## here we have the sops.
				JSON.parse(schedule_sop_events.first.arguments[:sops]).each do |sop_hash|
					sop = Auth.configuration.sop_class.constantize.new(sop_hash)
					expect(sop.orders).not_to be_empty
				end

				after_schedule_sop = schedule_sop_events.first.process
				expect(after_schedule_sop.size).to eq(1)
				after_schedule_sop = after_schedule_sop.first
				sops = JSON.parse(after_schedule_sop.arguments[:sops]).map{|c| c = Auth.configuration.sop_class.constantize.new(c)}
				expect(sops.size).to eq(1)
				
			end


			context " -- schedule order --  " do 

				context " -- transferring location information -- ", :transfer_location => true do 

					it " -- assigns the location information from the first cart item to the step if the step location information is blank -- ", :refact => true do 

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
						options[:order] = Auth.configuration.order_class.constantize.new(:cart_item_ids => cart_items.map{|c| c = c.id.to_s}).to_json
						search_sop_events = assembly.clone_to_add_cart_items(options)
						expect(search_sop_events.size).to eq(1)
						create_order_events = search_sop_events.first.process
						expect(create_order_events.size).to eq(1)
						schedule_sop_events = create_order_events.first.process
						expect(schedule_sop_events.size).to eq(1)
						after_schedule_sop = schedule_sop_events.first.process
						expect(after_schedule_sop.size).to eq(1)
						after_schedule_sop = after_schedule_sop.first
						sops = JSON.parse(after_schedule_sop.arguments[:sops]).map{|c| c = Auth.configuration.sop_class.constantize.new(c)}
						## each of these sop's should have the order in them.
						first_cart_item_location_information = cart_items.first.location_information
						sops.each do |sop|
							expect(sop.orders).not_to be_empty
							sop.steps.each_with_index {|step,step_key|
								address = "stages:#{sop.stage_index}:sops:#{sop.sop_index}:steps:#{step_key}"
								if first_cart_item_location_information[address]

									expect(step.location_information[:within_radius]).to eq(first_cart_item_location_information[address][:within_radius])
									expect(step.location_information[:location_point_coordinates]).to eq(first_cart_item_location_information[address][:location_point_coordinates])
								end

							}
						end
					
					end

					it "-- passes on location information from a previous step if the step does not have its own location information -- ", :step_pass => true do 

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

						options = {}
						options[:order] = Auth.configuration.order_class.constantize.new(:cart_item_ids => cart_items.map{|c| c = c.id.to_s}).to_json
						search_sop_events = assembly.clone_to_add_cart_items(options)
						expect(search_sop_events.size).to eq(1)
						create_order_events = search_sop_events.first.process
						expect(create_order_events.size).to eq(1)
						schedule_sop_events = create_order_events.first.process
						expect(schedule_sop_events.size).to eq(1)
						after_schedule_sop = schedule_sop_events.first.process
						expect(after_schedule_sop.size).to eq(1)
						after_schedule_sop = after_schedule_sop.first
						sops = JSON.parse(after_schedule_sop.arguments[:sops]).map{|c| c = Auth.configuration.sop_class.constantize.new(c)}
						## each of these sop's should have the order in them.
						first_cart_item_location_information = cart_items.first.location_information

						sops.each do |sop|
							expect(sop.orders).not_to be_empty
							sop.steps.each_with_index {|step,step_key|
								## if the key > 0
								## then we expect the location information to be 
								if step_key > 0
									expect(step.location_information["within_radius"]).to eq(20)
									expect(step.location_information["location_point_coordinates"]).to eq([10,20])
								end

								step.requirements.each_with_index{|rq,rq_index|

									if rq_index == 0

										expect(rq.location_information["within_radius"]).to eq(400)

										expect(rq.location_information["location_point_coordinates"]).to eq([40,450])


									else

										expect(rq.location_information["within_radius"]).to eq(20)

										expect(rq.location_information["location_point_coordinates"]).to eq([10,20])

									end	

								} 

							}
						end
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
						options[:order] = Auth.configuration.order_class.constantize.new(:cart_item_ids => cart_items.map{|c| c = c.id.to_s}).to_json
						search_sop_events = assembly.clone_to_add_cart_items(options)
						expect(search_sop_events.size).to eq(1)
						create_order_events = search_sop_events.first.process
						expect(create_order_events.size).to eq(1)
						schedule_sop_events = create_order_events.first.process
						expect(schedule_sop_events.size).to eq(1)
						after_schedule_sop = schedule_sop_events.first.process
						expect(after_schedule_sop.size).to eq(1)
						after_schedule_sop = after_schedule_sop.first
						sops = JSON.parse(after_schedule_sop.arguments[:sops]).map{|c| c = Auth.configuration.sop_class.constantize.new(c)}
						sops.each do |sop|
							sop.steps.each do |step|
								expect(step.resolved_location_id).not_to be_blank
							end
						end
	
					end

					it " -- resolves location provieded location coordinates and within radius and categories -- ", :resolve_coords do 

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
									
									## add a location id to all the steps and pass resolve to true on all of them.
									[0,1,2].each do |st_key|
										assembly.stages[key].sops[sop_key].steps[st_key].resolve = true	
										assembly.stages[key].sops[sop_key].steps[st_key].location_information[:location_point_coordinates] = {:lat => 10.11, :lng => 14.99}
										assembly.stages[key].sops[sop_key].steps[st_key].location_information[:within_radius] = 10
										assembly.stages[key].sops[sop_key].steps[st_key].location_information[:location_categories] = ["biochemistry_station"]
									end
								end 
							}
						}

						## the first thing to check is whether for each of those sops, each of the steps has been actually given a resolved id.



						## now we expect that all the resulting steps will have a location id.
						expect(assembly.save).to be_truthy

						## so now what.

						options = {}
						options[:order] = Auth.configuration.order_class.constantize.new(:cart_item_ids => cart_items.map{|c| c = c.id.to_s}).to_json
						search_sop_events = assembly.clone_to_add_cart_items(options)
						expect(search_sop_events.size).to eq(1)
						create_order_events = search_sop_events.first.process
						expect(create_order_events.size).to eq(1)
						schedule_sop_events = create_order_events.first.process
						expect(schedule_sop_events.size).to eq(1)
						after_schedule_sop = schedule_sop_events.first.process
						expect(after_schedule_sop.size).to eq(1)
						after_schedule_sop = after_schedule_sop.first
						sops = JSON.parse(after_schedule_sop.arguments[:sops]).map{|c| c = Auth.configuration.sop_class.constantize.new(c)}
						sops.each do |sop|
							sop.steps.each do |step|
								expect(step.resolved_location_id).not_to be_blank
							end
						end

					end


				end

				context " -- duration and time -- " do 

					
					it " -- either a duration or a duration_calculation_function has to be specified on the step -- ", :step_requires_duration do 

						step = Auth::Workflow::Step.new
						step.applicable = true
						sop = Auth::Workflow::Sop.new
						sop.steps << step
						stage = Auth::Workflow::Stage.new
						stage.sops << sop
						a = Auth::Workflow::Assembly.new
						a.stages << stage
						expect(a.save).not_to be_truthy
						expect(a.stages.first.sops.first.steps.first.valid?).not_to be_truthy
					end

								
				end

				context " -- requirement query hash function -- " do 
					context " -- no start time specification -- " do 
						context " -- requirement has a reference requirement -- " do 

							it " -- if requirement time requirements are continuous then expands the existing time range in the hash  -- ", :req_query_ref_continuous do 
										
								products = {}
								3.times do |n|
									p = Auth.configuration.product_class.constantize.new
									p.price = 30
									p.signed_in_resource = @admin
									expect(p.save).to be_truthy
									products[p.id.to_s] = p
								end

								a = Auth.configuration.assembly_class.constantize.new( applicable: true)
								
								stage = Auth.configuration.stage_class.constantize.new( applicable: true)
								
								sop = Auth.configuration.sop_class.constantize.new( applicable: true, applicable_to_product_ids: products.keys)
								
								step_one = Auth.configuration.step_class.constantize.new(applicable: true, duration: 300)


								step_one.time_information[:start_time_specification] = [["*","*","4","0","86300"]]

								step_one.time_information[:minimum_time_since_previous_step] = 0


								requirement_for_step_one = Auth.configuration.requirement_class.constantize.new(schedulable: true, applicable: true)

								step_one.requirements << requirement_for_step_one
								sop.steps << step_one
								stage.sops << sop
								a.stages << stage


								stage_two = Auth.configuration.stage_class.constantize.new(applicable: true)
								
								sop_two = Auth.configuration.sop_class.constantize.new(applicable: true, applicable_to_product_ids: products.keys)

								step_two = Auth.configuration.step_class.constantize.new(applicable: true, duration: 400)

								requirement_for_step_two = Auth.configuration.requirement_class.constantize.new(schedulable: true, applicable: true)

								requirement_for_step_two.reference_requirement_address = "stages:0:sops:0:steps:0:requirements:0"
								
								step_two.requirements << requirement_for_step_two
								sop_two.steps << step_two
								stage_two.sops << sop_two
								a.stages << stage_two
								a.master = true
								a.valid?
								#puts a.errors.full_messages.to_s
								expect(a.save).to be_truthy

								## create some cart items from the products.
								
								cart_items = []
								products.keys.each do |pr|
									puts pr.to_s
									
									cart_item = Auth.configuration.cart_item_class.constantize.new
									cart_item.product_id = pr
									cart_item.signed_in_resource = @u
									cart_item.resource_class = @u.class.name
									cart_item.resource_id = @u.id.to_s
									cart_item.valid?
									puts cart_item.errors.full_messages
									expect(cart_item.save).to be_truthy
									cart_items << cart_item
								end 

								## now let us first clone the assembly.
								options = {}
								options[:order] = Auth.configuration.order_class.constantize.new(:cart_item_ids => cart_items.map{|c| c = c.id.to_s}).to_json

								search_sop_events = a.clone_to_add_cart_items(options)
								
								expect(search_sop_events.size).to eq(1)
								
								

								create_order_events = search_sop_events.first.process
								
								expect(create_order_events.size).to eq(1)
								
								schedule_sop_events = create_order_events.first.process
								
								expect(schedule_sop_events.size).to eq(1)
								
								after_schedule_sop = schedule_sop_events.first.process
								
								expect(after_schedule_sop.size).to eq(1)
								
								after_schedule_sop = after_schedule_sop.first

								## now here we should get this to pass.


							end

							it " -- if requirement time requirements are not continuous then adds a new entry to the time requirements -- " do 


							end

						end

						context " -- requirement does not have a reference requirement -- " do 

							it " -- creates a new entry in the requirements query hash for this requirement -- " do 


							end

						end

					end

					context " -- start time specification -- " do 

						context " -- previous time information provided -- " do 

							context " -- requirement has a reference requirement -- " do 


							end

							context " -- requirement does not have a reference requirement -- " do 


							end

						end

						context " -- previous time information not provided -- " do 

							context " -- requirement has a reference requirement -- " do 


							end

							context " -- requirement does not have a reference requirement -- " do 


							end

						end

					end

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
						
						location_query = loc.generate_location_query({:lat => 10.0, :lng => 15.01},10,["biochemistry_station"])

						puts "query is:"
						puts location_query

						location_results = Auth.configuration.location_class.constantize.where(location_query)

						expect(location_results.size).to eq(2)

					end

				end	

		 	end
			
		end

	end

end