RSpec.describe Auth::System::Wrapper, type: :model, :definition_model => true do
  	

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

		before(:example) do 
			Auth::System::Wrapper.delete_all
			Auth.configuration.product_class.constantize.delete_all
			Auth.configuration.cart_item_class.constantize.delete_all
			Auth.configuration.location_class.constantize.delete_all
		end
		
		context " -- apply_time_specification -- " do 

			context " -- minute is wildcard -- " do 

				context " -- different elements of one unit have different start time specifications -- " do 

					it " -- raises an error if a common acceptable time cannot be found -- " do 

						response = create_from_file("/home/bhargav/Github/auth/spec/test_json_assemblies/system/4.json")
						
						wrapper = response[:wrapper]
						
						cart_items = response[:cart_items]
						
						products = response[:products]
						
						wrapper.add_cart_items(cart_items.map{|c| c = c.id.to_s})

						wrapper.levels.each do |level|
							level.branches.each do |branch|
								branch.add_cart_items
							end
						end
						
						expect{wrapper.levels[0].branches[0].do_schedule_queries}.to raise_error("start time range cannot be synchronized")

					end


					it " -- raises an error if no time specifications are found for any of the cart items -- " do 

						response = create_from_file("/home/bhargav/Github/auth/spec/test_json_assemblies/system/5.json")
						
						wrapper = response[:wrapper]
						
						cart_items = response[:cart_items]
						
						products = response[:products]
						
						wrapper.add_cart_items(cart_items.map{|c| c = c.id.to_s})

						wrapper.levels.each do |level|
							level.branches.each do |branch|
								branch.add_cart_items
							end
						end
						
						expect{wrapper.levels[0].branches[0].do_schedule_queries}.to raise_error("no start time range found")

					end


					it " -- the latest start_time_range beginning is chosen as the start time beginning and the earliest start time range end is chosen as the start_time_range end -- " do 

						response = create_from_file("/home/bhargav/Github/auth/spec/test_json_assemblies/system/6.json")
						

						wrapper = response[:wrapper]
						
						cart_items = response[:cart_items]
						
						products = response[:products]
						
						wrapper.add_cart_items(cart_items.map{|c| c = c.id.to_s})

						wrapper.levels.each do |level|
							level.branches.each do |branch|
								branch.add_cart_items
							end
						end
						
						wrapper.levels.each do |level|
							level.branches.each do |branch|
								branch.do_schedule_queries
							end
						end

						derived_time_spec = wrapper.levels[0].branches[0].definitions[0].time_specifications[0]

						expect(derived_time_spec[:start_time_range_end] - derived_time_spec[:start_time_range_beginning]).to eq(4500)

					end

				end

			end

			context " -- previous query intersections provide minutes -- " do 



			end

		end

		context " -- apply location specification -- " do 

			context " -- locations is wildcard -- " do 

				context " -- only location ids - " do 

					it " -- returns the common location ids after intersecting -- ", :common_locations => true do 
						
						response = create_from_file("/home/bhargav/Github/auth/spec/test_json_assemblies/system/7.json")
						

						wrapper = response[:wrapper]
						
						cart_items = response[:cart_items]
						
						products = response[:products]
						
						wrapper.add_cart_items(cart_items.map{|c| c = c.id.to_s})

						wrapper.levels.each do |level|
							level.branches.each do |branch|
								branch.add_cart_items
							end
						end
						
						wrapper.levels.each do |level|
							level.branches.each do |branch|
								branch.do_schedule_queries
							end
						end

						expect(wrapper.levels[0].branches[0].definitions[0].location_specifications[0][:location_ids]).to eq(["first_location"])


					end

					it " -- raises no common location if no common 	location can be found -- ", :no_common_location_ids => true do 

						response = create_from_file("/home/bhargav/Github/auth/spec/test_json_assemblies/system/8.json")
						

						wrapper = response[:wrapper]
						
						cart_items = response[:cart_items]
						
						products = response[:products]
						
						wrapper.add_cart_items(cart_items.map{|c| c = c.id.to_s})

						wrapper.levels.each do |level|
							level.branches.each do |branch|
								branch.add_cart_items
							end
						end
						
						expect{wrapper.levels[0].branches[0].do_schedule_queries}.to raise_error("could not find common location ids")
						
					end

				end

				context " -- location ids and within radius are both provided -- " do 

					it " -- finds only those location ids within the radius of the provided location id -- ", :radius_location_query => true do 

						response = create_from_file("/home/bhargav/Github/auth/spec/test_json_assemblies/system/9.json")
						
						wrapper = response[:wrapper]
						
						cart_items = response[:cart_items]
						
						products = response[:products]
						
						wrapper.add_cart_items(cart_items.map{|c| c = c.id.to_s})

						wrapper.levels.each do |level|
							level.branches.each do |branch|
								branch.add_cart_items
							end
						end
						
						wrapper.levels.each do |level|
							level.branches.each do |branch|
								branch.do_schedule_queries
							end
						end

						expect(wrapper.levels[0].branches[0].definitions[0].location_specifications).to eq([{:location_ids=>["first_location"]}])

					end




					it " -- raises no common location id found error, if the provided location ids are not within the given radius -- " do

						response = create_from_file("/home/bhargav/Github/auth/spec/test_json_assemblies/system/10.json")
						
						wrapper = response[:wrapper]
						
						cart_items = response[:cart_items]
						
						products = response[:products]
						
						wrapper.add_cart_items(cart_items.map{|c| c = c.id.to_s})

						wrapper.levels.each do |level|
							level.branches.each do |branch|
								branch.add_cart_items
							end
						end

						expect{wrapper.levels[0].branches[0].do_schedule_queries}.to raise_error("could not find common location ids")

					end


					it " -- raises no common location id found error , if the provided location ids are not in the categories specified in the within radius location specification --" do 

						response = create_from_file("/home/bhargav/Github/auth/spec/test_json_assemblies/system/11.json")
						
						wrapper = response[:wrapper]
						
						cart_items = response[:cart_items]
						
						products = response[:products]
						
						wrapper.add_cart_items(cart_items.map{|c| c = c.id.to_s})

						wrapper.levels.each do |level|
							level.branches.each do |branch|
								branch.add_cart_items
							end
						end

						expect{wrapper.levels[0].branches[0].do_schedule_queries}.to raise_error("could not find common location ids")

					end

					it " -- adds an empty result to the location information if no location information is found or available -- " do 

						response = create_from_file("/home/bhargav/Github/auth/spec/test_json_assemblies/system/12.json")
						
						wrapper = response[:wrapper]
						
						cart_items = response[:cart_items]
						
						products = response[:products]
						
						wrapper.add_cart_items(cart_items.map{|c| c = c.id.to_s})

						wrapper.levels.each do |level|
							level.branches.each do |branch|
								branch.add_cart_items
							end
						end
						
						wrapper.levels.each do |level|
							level.branches.each do |branch|
								branch.do_schedule_queries
							end
						end		
						
						expect(wrapper.levels[0].branches[0].definitions[0].location_specifications).to eq([{}])		

					end

				end

			end

		end

		context " -- build query overlap hash -- " do 

			it " -- accepts a query result as an argument -- " do 

				## should query result be an object or a simple hash ?
				## it is basically going to be like :
				## minute -> location -> entity_category => [ids]
				## so let it be a hash of hashes.
				## as far as overlap hash is concerned, let it be , an object.

			end

			it " -- adds a range to the hash -- " do 


			end


			it " -- splits an existing range in the hash, and updates the capacity -- " do 


			end

		end

		context " -- do query -- " do 
			## now we need to search for the entity categories.
			context " -- no location information -- " do 

				it " -- searches for minutes with required entity categories -- " do 



				end

			end

			context " -- location information -- " do 
				
				context " -- within radius type -- " do 
					
					context " -- transit speed is provided -- " do 

						it " -- does the transit type of query -- " do 

							## so here we have to give the definition the required entity categories.
							## before doing this will have to do the overlap.
							## because it has to refer to the overlap before formulating the query.
							##

						end

					end

					context " -- no transit speed -- " do 

					end

				end

				context " -- location ids type -- " do 

					it " -- finds the minutes with the required entity categories, "

				end

			end

		end

	end

end