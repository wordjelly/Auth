require 'rails_helper'


RSpec.describe Auth::System::Wrapper, type: :model, :wrapper_model => true do
  	

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
		end


		context " -- load from json -- " do 

			it " -- loads wrapper from json file -- " do 

				response = create_from_file("/home/bhargav/Github/auth/spec/test_json_assemblies/system/1.json")
				wrapper = response[:wrapper]
				expect(wrapper.address).to be_nil
				wrapper.levels.each_with_index {|l,lindex|
					expect(l.address).to eq("l#{lindex}")
					l.branches.each_with_index{|b,bindex|
						expect(b.address).to eq(l.address + ":b#{bindex}")
						b.definitions.each_with_index{|d,dindex|
							expect(d.address).to eq(b.address + ":d#{dindex}")
							d.units.each_with_index{|u,uindex|
								expect(u.address).to eq(d.address + ":u#{uindex}")
							}
						}
					}
				}
				
			end



		end

		context " -- adding of cart items -- " do 

			context " -- locates brance, defintion and creation -- " do 

				context " -- address provided -- " do 

				end

				context " -- address not provided -- " do 

					it  " -- wrapper adds cart_items to applicable branches. -- " do 

						response = create_from_file("/home/bhargav/Github/auth/spec/test_json_assemblies/system/2.json")
						wrapper = response[:wrapper]
						cart_items = response[:cart_items]
						products = response[:products]
						wrapper.add_cart_items(cart_items.map{|c| c = c.id.to_s})
						expect(wrapper.levels[0].branches[0].input_object_ids.size).to eq(2)
						
					end


					it " -- wrapper raises branch not found error, if a branch could not be found for a cart item -- " do 

												
					end
					
					it " -- branch input objects are added to definitions based on group key -- " do 

						response = create_from_file("/home/bhargav/Github/auth/spec/test_json_assemblies/system/3.json")
						wrapper = response[:wrapper]
						cart_items = response[:cart_items]
						products = response[:products]
						wrapper.add_cart_items(cart_items.map{|c| c = c.id.to_s})
						wrapper.levels.each do |level|
							level.branches.each do |branch|
								branch.add_cart_items
							end
						end
						expect(wrapper.levels[0].branches[0].definitions[0].input_object_ids.size).to eq(2)
					end

					it " -- raises no definition satisfied if no definition can be found for all the cart items -- " do 


					end


				end

			end

		end

		context " -- schedule -- " do 

			context " -- multiple units in individual input object id elements -- " do 

				context " -- no previous query results -- " do 
					
					it " -- adds a wildcard entry into the intersection results. -- ", :wildcard => true do 	

						response = create_from_file("/home/bhargav/Github/auth/spec/test_json_assemblies/system/3.json")
						
						wrapper = response[:wrapper]
						
						cart_items = response[:cart_items]
						
						products = response[:products]
						
						wrapper.add_cart_items(cart_items.map{|c| c = c.id.to_s})

						wrapper.levels.each do |level|
							level.branches.each do |branch|
								branch.add_cart_items
							end
						end
						
						expect(wrapper.levels[0].branches[0].definitions[0].input_object_ids.size).to eq(2)

						wrapper.levels.each do |level|
							level.branches.each do |branch|
								branch.do_schedule_queries
							end
						end

						expect(wrapper.levels[0].branches[0].definitions[0].intersection_results[0]).to eq([{:minute=>"*", :locations=>["*"]}])

					end


					it " -- checks time specified in the cart_item for congruence with time specifications, and sets a common time specification for the query -- " do 

						## so each cart item will have a certain start time mentioned on it.
						## so this becomes the fallback for the set_time_specifications function.

					end

					it " -- checks location specified in the cart_item for congruence with locations specifications, and sets a common location specification for the query -- " do 


					end

				end

			end

		end

		context " -- overlap hash -- ", :overlap_hash => true do 

			context " -- unit tests -- " do 
				
				context " -- manage minute -- " do 

					it " -- manages equal minute -- " do 
						wrapper = Auth::System::Wrapper.new
						
						wrapper.overlap_hash = {
							"abc" => {
								10 => {
									"c1_c2_c3" => {
										:query_ids => ["10","12"]
									}
								}
							}
						}

						minute_hash_to_merge = {
							"c1_c2_c3" => {
								:categories => ["c1","c2","c3"],
								:query_ids => ["1"]
							}
						}

						minute = 10
						
						location_id = "abc"

						## now we will call manage_minute on this wrapper 

						wrapper.manage_minute(minute_hash_to_merge,minute,location_id)

						#puts JSON.pretty_generate(wrapper.overlap_hash)
						wrapper.overlap_hash.deep_symbolize_keys!
						#puts "this is the overlap hash at location id"
						#puts wrapper.overlap_hash[location_id.to_sym][minute]["c1_c2_c3".to_sym][:query_ids].to_s
						expect(wrapper.overlap_hash[location_id.to_sym][minute]["c1_c2_c3".to_sym][:query_ids]).to eq(["10","12","1"])

					end

					it " -- manages only lower minute -- " do 

						## so it should just add this minute.
						## nothing more.

						wrapper = Auth::System::Wrapper.new
						
						wrapper.overlap_hash = {
							"abc" => {
								8 => {
									"c1_c2_c3" => {
										:query_ids => ["10","12"]
									}
								}
							}
						}

						minute_hash_to_merge = {
							"c1_c2_c3" => {
								:categories => ["c1","c2","c3"],
								:query_ids => ["1"]
							}
						}

						minute = 10
						
						location_id = "abc"

						wrapper.manage_minute(minute_hash_to_merge,minute,location_id)

						#puts JSON.pretty_generate(wrapper.overlap_hash)
						wrapper.overlap_hash.deep_symbolize_keys!
						expect(wrapper.overlap_hash[location_id.to_sym][minute]["c1_c2_c3".to_sym][:query_ids]).to eq(["1"])


					end

					it " -- manages only higher minute -- " do 

						## it should just add the minute.
						wrapper = Auth::System::Wrapper.new
						
						wrapper.overlap_hash = {
							"abc" => {
								12 => {
									"c1_c2_c3" => {
										:query_ids => ["10","12"]
									}
								}
							}
						}

						minute_hash_to_merge = {
							"c1_c2_c3" => {
								:categories => ["c1","c2","c3"],
								:query_ids => ["1"]
							}
						}

						minute = 10
						
						location_id = "abc"

						wrapper.manage_minute(minute_hash_to_merge,minute,location_id)

						#puts JSON.pretty_generate(wrapper.overlap_hash)
						wrapper.overlap_hash.deep_symbolize_keys!
						expect(wrapper.overlap_hash[location_id.to_sym][minute]["c1_c2_c3".to_sym][:query_ids]).to eq(["1"])

					end

					it " -- manages higher and lower minute -- ", :combined_minute => true do 

						## in this case it will fuse the stuff from the lower minute.
						wrapper = Auth::System::Wrapper.new
						
						wrapper.overlap_hash = {
							"abc" => {
								1 => {
									"c1_c2_c3" => {
										:query_ids => ["10","12"]
									}
								},
								12 => {
									"c1_c2_c3" => {
										:query_ids => ["10","12"]
									}
								}
							}
						}

						minute_hash_to_merge = {
							"c1_c2_c3" => {
								:categories => ["c1","c2","c3"],
								:query_ids => ["1"]
							}
						}

						minute = 10
						
						location_id = "abc"

						wrapper.manage_minute(minute_hash_to_merge,minute,location_id)

						wrapper.overlap_hash.deep_symbolize_keys!

						## we expect this to have the query ids, 10,12,1 at the minute 10.
						wrapper.overlap_hash.deep_symbolize_keys!
						expect(wrapper.overlap_hash[location_id.to_sym][minute]["c1_c2_c3".to_sym][:query_ids]).to eq(["10","12","1"])
						expect(wrapper.overlap_hash[location_id.to_sym][1]["c1_c2_c3".to_sym][:query_ids]).to eq(["10","12"])

					end

				end

				context " -- manage start and end minutes together -- ", :se_together => true do

					it " -- adds start and end minute in between two existing minutes -- " do 

						wrapper = Auth::System::Wrapper.new
						
						wrapper.overlap_hash = {
							"abc" => {
								1 => {
									"c1_c2_c3" => {
										:query_ids => ["10","12"]
									}
								},
								12 => {
									"c1_c2_c3" => {
										:query_ids => ["10","12"]
									}
								}
							}
						}


						
						minute_to_insert = {
							"c1_c2_c3" => {
								:categories => ["c1","c2","c3"],
								:query_ids => ["1"]
							}
						}

						start_minute = 5
						end_minute = 7
						location_id = "abc"

						wrapper.manage_minute(minute_to_insert,end_minute,location_id)

						## now when its adding the start minute, what is the problem.
						## it is adding both 
						wrapper.manage_minute(minute_to_insert,start_minute,location_id)

						#puts JSON.pretty_generate(wrapper.overlap_hash)
						## 5 and 7 should have similar shit in them.s

						wrapper.overlap_hash.deep_symbolize_keys!

						expect(wrapper.overlap_hash[location_id.to_sym][5]["c1_c2_c3".to_sym][:query_ids]).to eq(["10","12","1"])
						expect(wrapper.overlap_hash[location_id.to_sym][7]["c1_c2_c3".to_sym][:query_ids]).to eq(["10","12","1"])
					end 	

				end

			end

			

		end

	end

end
