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
			Auth.configuration.location_class.constantize.delete_all
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

						wrapper.manage_minute(minute_to_insert,start_minute,location_id)

						#puts JSON.pretty_generate(wrapper.overlap_hash)
						## 5 and 7 should have similar shit in them.s

						wrapper.overlap_hash.deep_symbolize_keys!

						expect(wrapper.overlap_hash[location_id.to_sym][5]["c1_c2_c3".to_sym][:query_ids]).to eq(["10","12","1"])
						expect(wrapper.overlap_hash[location_id.to_sym][7]["c1_c2_c3".to_sym][:query_ids]).to eq(["10","12","1"])
					end 	

				end

				context " -- updates intervening minutes -- ", :update_intervening_minutes => true do 

					it " -- adds the query ids of the lower minute to all the intervening minutes -- " do 

						wrapper = Auth::System::Wrapper.new
						
						wrapper.overlap_hash = {
							"abc" => {
								3 => {
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

						start_minute = 1
						end_minute = 15
						location_id = "abc"

						wrapper.manage_minute(minute_to_insert,end_minute,location_id)
						
						wrapper.manage_minute(minute_to_insert,start_minute,location_id)

						wrapper.update_intervening_minutes(minute_to_insert,start_minute,end_minute,location_id)

						wrapper.overlap_hash.deep_symbolize_keys!

						expect(wrapper.overlap_hash[location_id.to_sym][3]["c1_c2_c3".to_sym][:query_ids]).to eq(["10","12","1"])

						expect(wrapper.overlap_hash[location_id.to_sym][12]["c1_c2_c3".to_sym][:query_ids]).to eq(["10","12","1"])
						
						expect(wrapper.overlap_hash[location_id.to_sym][1]["c1_c2_c3".to_sym][:query_ids]).to eq(["1"])

						expect(wrapper.overlap_hash[location_id.to_sym][15]["c1_c2_c3".to_sym][:query_ids]).to eq(["1"])
					end

				end

				context " -- integrated overlap hash population test -- ", :populate_overlap_hash => true do 

					it " -- populates virgin overlap hash. -- " do 
						query_result = get_location_aggregation_result
						query_result = query_result.to_a
						categories_searched_for = ["a","b","c"]
						query_id = "first_query"
						wrapper = Auth::System::Wrapper.new
						
						wrapper.update_overlap_hash(query_result,categories_searched_for,query_id)
						
						wrapper.overlap_hash.deep_symbolize_keys!

						expect(wrapper.overlap_hash["first_location".to_sym][1]["a_b_c".to_sym][:query_ids]).to eq(["first_query"])

						expect(wrapper.overlap_hash["first_location".to_sym][20]["a_b_c".to_sym][:query_ids]).to eq(["first_query"]) 

						expect(wrapper.overlap_hash["second_location".to_sym][7]["a_b_c".to_sym][:query_ids]).to eq(["first_query"])

						expect(wrapper.overlap_hash["second_location".to_sym][17]["a_b_c".to_sym][:query_ids]).to eq(["first_query"]) 

					end

					it " -- populates preloaded overlap hash -- ", :preloaded_overlap_hash => true do 
						## here we want to ensure that it is correctly loading the overlap hash.
						## so first we have an overlap hash, and then we add some stuff into it.
						## so for the first location lets have nothing in the overlap hash already.
						## for the second location, we have one minute less and one in the middle of the incoming minutes.
						wrapper = Auth::System::Wrapper.new
						
						wrapper.overlap_hash = {
							"second_location" => {
								5 => {
									"a_b_c" => {
										:query_ids => ["10","12"]
									}
								},
								20 => {
									"a_b_c" => {
										:query_ids => ["10","12"]
									}
								}
							}
						}

						query_result = get_location_aggregation_result
						query_result = query_result.to_a
						categories_searched_for = ["a","b","c"]
						query_id = "first_query"
						
						wrapper.update_overlap_hash(query_result,categories_searched_for,query_id)
						
						wrapper.overlap_hash.deep_symbolize_keys!

						######## FOR SECOND RYHTYM

						expect(wrapper.overlap_hash["first_location".to_sym][1]["a_b_c".to_sym][:query_ids]).to eq(["first_query"])

						expect(wrapper.overlap_hash["first_location".to_sym][20]["a_b_c".to_sym][:query_ids]).to eq(["first_query"]) 

						########## FOR SECOND LOCATION.

						expect(wrapper.overlap_hash["second_location".to_sym][7]["a_b_c".to_sym][:query_ids]).to eq(["10","12","first_query"])

						expect(wrapper.overlap_hash["second_location".to_sym][17]["a_b_c".to_sym][:query_ids]).to eq(["10","12","first_query"])

						expect(wrapper.overlap_hash["second_location".to_sym][5]["a_b_c".to_sym][:query_ids]).to eq(["10","12"])

						expect(wrapper.overlap_hash["second_location".to_sym][20]["a_b_c".to_sym][:query_ids]).to eq(["10","12"])
						

					end

				end

				context " -- filters query results -- ", :filter_query_results => true do 

					## here we will first test the filtering code in a unit test.

					context " -- unit test -- " do

						it " -- gives applicable minute only if directly equal or between two existing minutes -- " do 

							wrapper = Auth::System::Wrapper.new
						
							wrapper.overlap_hash = {
								"second_location" => {
									5 => {
										"a_b_c" => {
											:query_ids => ["10","12","14"]
										}
									},
									20 => {
										"a_b_c" => {
											:query_ids => ["10","12","14"]
										}
									}
								}
							}	
							
							## so what will is it expected to do here.
							## ?
							## we already have a_b_c, at the lesser than minute
							## so all the categories intersect.
							## from the minute in the overlap hash.
							## for the combination in the incoming minute.
							## the question is whether the capacity is sufficient or not.
							## let me first make the query ids return true.
							## that will automatically increment the capacity and the query_result should get pruned.
							query_result = get_location_aggregation_result
							categories_searched_for = ["a","b","c"]
							query_id = "first_query"

							query_result = query_result.to_a
							query_result = wrapper.filter_query_results(query_result,categories_searched_for,query_id)

							## the location id "second_location" should have had all its minutes pruned out.
							query_result[0]["minutes"].each do |min|
								expect(min).to be_empty
							end

						end

						context " -- applicable minute found -- " do 

							it " -- does not prune unless some common categories are found -- ", :no_common_categories => true do 

								## okay so here is lack of common categories.
								## in thise case, there are no common categories.
								## in between the one's searched for and the one in the overlap hash.
								## so the overlap hash shduld have 	something else.
								wrapper = Auth::System::Wrapper.new
						
								wrapper.overlap_hash = {
									"second_location" => {
										5 => {
											"a2_b2_c2" => {
												:query_ids => ["10","12","14"]
											}
										},
										20 => {
											"a2_b2_c2" => {
												:query_ids => ["10","12","14"]
											}
										}
									}
								}	

								## now there should be no pruning, the query_results should be the same before and after.
								query_result = get_location_aggregation_result
								categories_searched_for = ["a","b","c"]
								query_id = "first_query"

								query_result = query_result.to_a
								filtered_query_results = wrapper.filter_query_results(query_result,categories_searched_for,query_id)
								expect(filtered_query_results).to eq(query_result)

							end

							it " -- does not prune unless all the categories in the combination are there in the minute -- " do 

								## so some of the categories in the overlap are there in the minute, but not all, so in that case it will not be applicable.
								## so in the overlap we keep a,b,f
								## and in the minute there are a,b,c

								## so let us say that 
								wrapper = Auth::System::Wrapper.new
						
								wrapper.overlap_hash = {
									"second_location" => {
										5 => {
											"a_b_c2" => {
												:query_ids => ["10","12","14"]
											}
										},
										20 => {
											"a_b_c2" => {
												:query_ids => ["10","12","14"]
											}
										}
									}
								}	

								## now there should be no pruning, the query_results should be the same before and after.
								query_result = get_location_aggregation_result
								categories_searched_for = ["a","b","c"]
								query_id = "first_query"

								query_result = query_result.to_a
								filtered_query_results = wrapper.filter_query_results(query_result,categories_searched_for,query_id)
								expect(filtered_query_results).to eq(query_result)

							end

						end

					end

				end


				context " -- first populate empty overlap hash, then filter subsequent query", :populate_then_filter => true do 

					it " -- first query and second query will be same, so the second query leads to complete pruning -- " do 
						query_result = get_location_aggregation_result
						categories_searched_for = ["a","b","c"]
						query_id = "first_query"

						## now we directly call the main function.
						wrapper = Auth::System::Wrapper.new

						query_result = query_result.to_a

						wrapper.process_query_results(query_result,categories_searched_for,query_id)

						
						categories_searched_for = ["a","b","c"]
						query_id = "second_query"

						

						wrapper.process_query_results(query_result,categories_searched_for,query_id)		

						## so basically what will happen here is that everything from the second result will get pruned out.

						## the query result should be empty, in all respects.
						query_result[0]["minutes"].each do |min|
								expect(min).to be_empty
						end

					end

				end


				context " -- first populate empty overlap hash, then filter subsequent query, then add the filtered query results to the overlap hash -- " do 

					## okay so this time, everything does not get filtered
					## some things are in common so they get filtered, the rest of it gets added.
					## this is the last test


				end

			end			

		end

	end

end

## add / remove / delay / batched updates : 4 (day after and after that.)
## backtrace, merge, query id tracing : 4 (tomorrow.)
## adding barcode ids, and also serial/numbers, mark requirements : 4
## step video / image coordination : 4
## api to add step instructions, and actually add the sop's : 4

## to do after june 7th

## chat : 2 days
## location : 2 days
## b2b site
## test object + guideline : 6 days
## integration into shopping cart : 3 days
## apis for symptom test, survey, animation and image : 4 days
## actual deployment
