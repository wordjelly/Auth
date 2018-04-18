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

			it " -- returns empty response if no sop's are found -- ", :first_test => true do 
				
				assembly = load_assembly_from_json("/home/bhargav/Github/auth/spec/test_json_assemblies/2.json")

				expect(assembly.save).to be_truthy

				products = build_and_save_products(2,@admin)
				
				cart_items = build_and_save_cart_items(products,@u)

				pipeline_results = pipeline({:search_sop_events => true, :create_order_events => true},assembly,cart_items)

				expect(pipeline_results[:create_order_events]).to be_empty

			end

			it " -- finds applicable sops, and creates an event that will create the order in all those sops. -- ", :second_test => true do 
	
				assembly = load_assembly_from_json("/home/bhargav/Github/auth/spec/test_json_assemblies/1.json")

				assembly_products_and_cart_items = update_assembly_with_products_and_create_cart_items(assembly,@admin,@u)

				assembly = assembly_products_and_cart_items[:assembly]

				cart_items = assembly_products_and_cart_items[:cart_items]

				pipeline_results = pipeline({:search_sop_events => true, :create_order_events => true, :schedule_sop_events => true, :after_schedule_sop => true},assembly,cart_items)

				expect(pipeline_results[:schedule_sop_events]).not_to be_empty
			
			end

			
			context " -- schedule order --  " do 

				context " -- transferring location information -- ", :transfer_location => true do 

					it " -- assigns the location information from the first cart item to the step if the step location information is blank -- ", :third_test => true do 

						assembly = load_assembly_from_json("/home/bhargav/Github/auth/spec/test_json_assemblies/3.json")

						assembly_products_and_cart_items = update_assembly_with_products_and_create_cart_items(assembly,@admin,@u)

						assembly = assembly_products_and_cart_items[:assembly]

						cart_items = assembly_products_and_cart_items[:cart_items]

						products = assembly_products_and_cart_items[:products]

						## modify the cart items to add the location data.
						cart_items.map!{|c| 
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

						pipeline_results = pipeline({:search_sop_events => true, :create_order_events => true, :schedule_sop_events => true, :after_schedule_sop => true},assembly,cart_items)

						sops = JSON.parse(pipeline_results[:after_schedule_sop][:arguments][:sops]).map{|c| c = Auth.configuration.sop_class.constantize.new(c)}
						## now check in after_schedule_sop where we should save the modified sop' as arguments.
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

					it "-- passes on location information from a previous step if the step does not have its own location information -- ", :fourth_test => true do 


						assembly = load_assembly_from_json("/home/bhargav/Github/auth/spec/test_json_assemblies/4.json")

						assembly_products_and_cart_items = update_assembly_with_products_and_create_cart_items(assembly,@admin,@u)

						assembly = assembly_products_and_cart_items[:assembly]

						cart_items = assembly_products_and_cart_items[:cart_items]

						products = assembly_products_and_cart_items[:products]

						pipeline_results = pipeline({:search_sop_events => true, :create_order_events => true, :schedule_sop_events => true, :after_schedule_sop => true},assembly,cart_items)

						sops = JSON.parse(pipeline_results[:after_schedule_sop][:arguments][:sops]).map{|c| c = Auth.configuration.sop_class.constantize.new(c)}

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
							}
						end

					end

				end

				context " -- resolve --  " do 
				
					it " -- resolves location provided location id -- ", :fifth_test => true do 

						assembly = load_assembly_from_json("/home/bhargav/Github/auth/spec/test_json_assemblies/location_id_test.json")

						assembly_products_and_cart_items = update_assembly_with_products_and_create_cart_items(assembly,@admin,@u)

						assembly = assembly_products_and_cart_items[:assembly]

						cart_items = assembly_products_and_cart_items[:cart_items]

						products = assembly_products_and_cart_items[:products]

						pipeline_results = pipeline({:search_sop_events => true, :create_order_events => true, :schedule_sop_events => true, :after_schedule_sop => true},assembly,cart_items)

						sops = JSON.parse(pipeline_results[:after_schedule_sop][:arguments][:sops]).map{|c| c = Auth.configuration.sop_class.constantize.new(c)}

						first_cart_item_location_information = cart_items.first.location_information


						## add shit here.
						sops.each do |sop|
							sop.steps.each do |step|
								expect(step.resolved_location_id).not_to be_blank
							end
						end
	
					end

					it " -- resolves location provieded location coordinates and within radius and categories -- ", :sixth_test do 

=begin
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
=end

						assembly = load_assembly_from_json("/home/bhargav/Github/auth/spec/test_json_assemblies/location_coordinates_and_some_with_categories_test.json")

						assembly_products_and_cart_items = update_assembly_with_products_and_create_cart_items(assembly,@admin,@u)

						assembly = assembly_products_and_cart_items[:assembly]

						cart_items = assembly_products_and_cart_items[:cart_items]

						products = assembly_products_and_cart_items[:products]

						pipeline_results = pipeline({:search_sop_events => true, :create_order_events => true, :schedule_sop_events => true, :after_schedule_sop => true},assembly,cart_items)

						sops = JSON.parse(pipeline_results[:after_schedule_sop][:arguments][:sops]).map{|c| c = Auth.configuration.sop_class.constantize.new(c)}

						first_cart_item_location_information = cart_items.first.location_information

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
									
								assembly = load_assembly_from_json("/home/bhargav/Github/auth/spec/test_json_assemblies/1.json")

								
								assembly_products_and_cart_items = update_assembly_with_products_and_create_cart_items(assembly,@admin,@u)

								assembly = assembly_products_and_cart_items[:assembly]

								cart_items = assembly_products_and_cart_items[:cart_items]

								pipeline_results = pipeline({:search_sop_events => true, :create_order_events => true, :schedule_sop_events => true, :after_schedule_sop => true},assembly,cart_items)

								
								requirement_query_hash = JSON.parse(pipeline_results[:after_schedule_sop][:arguments][:requirement_query_hash])

								
								first_requirement = requirement_query_hash["stages:0:sops:0:steps:0:requirements:0"][0]

								expect(first_requirement["end_time_range"][0] - first_requirement["start_time_range"][0]).to eq(600)

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