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

			## first finalize the queries from location queries.

			context " -- loads overlap hash -- " do 

				it " -- does a transport query and loads the results into the overlap hash -- ", :simple_overlap => true do 

					wrapper = Auth::System::Wrapper.new

					response = wrapper.update_overlap_hash(response,location_info_array,"first_query")

					puts wrapper.overlap_hash
					expect(wrapper.overlap_hash.to_s).to eq('{:"5b04851f421aa910c46a01a2"=>{:"1"=>{:consumables=>{}, :categories=>{:a=>{:category_names=>["a"], :query_ids=>{:first_query=>{:"5b04851f421aa910c46a01a2_5b04851f421aa910c46a01a2"=>1}}}}}}}')

				end

			end


			context " -- unit tests -- " do 
	
				context " -- filters and updates overlap hash -- " do 


				end

				context " -- filters query results -- ", :filter_query_results => true do 

					it " -- common categories between searched categories and categories in result minute -- " do 
						
						## it should prune the result from the location hash.
						## because we are using a 

						wrapper = Auth::System::Wrapper.new
						
						wrapper.overlap_hash = load_overlap_hash("/home/bhargav/Github/auth/spec/test_json_assemblies/overlap_hashes/1.json")
						
						wrapper.overlap_hash.deep_symbolize_keys!

						location_info_array = 
						[
							{
								"start_time_range_beginning" => 0,
								"start_time_range_end" => 100,
								"duration" => 500,
								"location_id" => BSON::ObjectId(lr("first_location")),
								"categories" => [
									{
										"category" => "a",
										"arrives_at_location_categories" => ["l1"],
										"transport_capacity" => 1
									}
								]
							}
						]

						response = get_transport_location_result(location_info_array)

						wrapper.filter_query_results(response,location_info_array,"second_query")



					end

				end

				context " -- manage minute -- ", :manage_minute => true do 

					it " -- manages equal minute -- ", :manage_equal_minute => true do 
						wrapper = Auth::System::Wrapper.new
						
						wrapper.overlap_hash = load_overlap_hash("/home/bhargav/Github/auth/spec/test_json_assemblies/overlap_hashes/1.json")
						
						wrapper.overlap_hash.deep_symbolize_keys!

						location_info_array = 
						[
							{
								"start_time_range_beginning" => 0,
								"start_time_range_end" => 100,
								"duration" => 500,
								"location_id" => BSON::ObjectId(lr("first_location")),
								"categories" => [
									{
										"category" => "a",
										"arrives_at_location_categories" => ["l1"],
										"transport_capacity" => 10
									}
								]
							}
						]

						response = get_transport_location_result(location_info_array)

						wrapper.update_overlap_hash(response,location_info_array,"second_query")

						puts wrapper.overlap_hash
						#expect(wrapper.overlap_hash.to_s).to eq('{:"5b04851f421aa910c46a01a2"=>{:"1"=>{:consumables=>{}, :categories=>{:a=>{:category_names=>["a"], :query_ids=>{:first_query=>{:"5b04851f421aa910c46a01a2_5b04851f421aa910c46a01a2"=>1}, :second_query=>{:"5b04851f421aa910c46a01a2_5b04851f421aa910c46a01a2"=>1}}}}}}}')
						
					end


					## existing minute is 2
					## it finds 1
					it " -- manage lower minute -- ", :lower_minute => true do 

						wrapper = Auth::System::Wrapper.new
							
						wrapper.overlap_hash = load_overlap_hash("/home/bhargav/Github/auth/spec/test_json_assemblies/overlap_hashes/2.json")
							
						wrapper.overlap_hash.deep_symbolize_keys!

						location_info_array = 
							[
								{
									"start_time_range_beginning" => 0,
									"start_time_range_end" => 100,
									"duration" => 500,
									"location_id" => BSON::ObjectId(lr("first_location")),
									"categories" => [
										{
											"category" => "a",
											"arrives_at_location_categories" => ["l1"],
											"transport_capacity" => 10
										}
									]
								}
							]

						response = get_transport_location_result(location_info_array)

						wrapper.update_overlap_hash(response,location_info_array,"second_query")

						## there should be two things in that.
						expect(wrapper.overlap_hash["5b04851f421aa910c46a01a2".to_sym].keys.size).to eq(2)
					end

					## existing minute is 1
					## it finds 2.
					## so what happens in this case
					## nothing it is just expected to add the minute.
					it " -- manage higher minute -- ", :higher_minute => true do 

						wrapper = Auth::System::Wrapper.new
							
						wrapper.overlap_hash = load_overlap_hash("/home/bhargav/Github/auth/spec/test_json_assemblies/overlap_hashes/1.json")
							
						wrapper.overlap_hash.deep_symbolize_keys!

						location_info_array = 
							[
								{
									"start_time_range_beginning" => 0,
									"start_time_range_end" => 100,
									"duration" => 500,
									"location_id" => BSON::ObjectId(lr("first_location")),
									"categories" => [
										{
											"category" => "a",
											"arrives_at_location_categories" => ["l1"],
											"transport_capacity" => 10
										}
									]
								}
							]

						response = get_transport_location_result(location_info_array,"3.json")

						wrapper.update_overlap_hash(response,location_info_array,"second_query")

						## there should be two things in that.
						expect(wrapper.overlap_hash["5b04851f421aa910c46a01a2".to_sym].keys.size).to eq(2)

					end

					## existing is 2
					## it finds 
					## 1 and 10
					## so it should incorporate everything from 1  into 2
					## and add 1, and 10.
					it " -- manages higher and lower minute -- ", :higher_and_lower_minute => true do 

						wrapper = Auth::System::Wrapper.new
							
						wrapper.overlap_hash = load_overlap_hash("/home/bhargav/Github/auth/spec/test_json_assemblies/overlap_hashes/2.json")
							
						wrapper.overlap_hash.deep_symbolize_keys!

						location_info_array = 
							[
								{
									"start_time_range_beginning" => 0,
									"start_time_range_end" => 100,
									"duration" => 500,
									"location_id" => BSON::ObjectId(lr("first_location")),
									"categories" => [
										{
											"category" => "a",
											"arrives_at_location_categories" => ["l1"],
											"transport_capacity" => 10
										}
									]
								}
							]

						response = get_transport_location_result(location_info_array,"4.json")

						wrapper.update_overlap_hash(response,location_info_array,"second_query")

						puts JSON.pretty_generate(wrapper.overlap_hash)

						
						expect(wrapper.overlap_hash["5b04851f421aa910c46a01a2".to_sym]["2".to_sym][:categories]["a".to_sym][:query_ids].keys.size).to eq(2)

					end

				end

			end			

		end

	end

end

## after this there is still filter, and then the requery, and then the making of the actual hash of the synchronized ids
## at least 2-3 days more will go in all this.
## there is also merge.
## step synchronization i will add later on.
## and query forking, based on next query situations.

## then there is the dynamic rescheduling.

## add / remove / delay / batched updates(2) + 1 : 4 (day after and after that.)

## backtrace(2) + (1) test, merge, query id tracing : 4 (tomorrow.)

## adding barcode ids, and also serial/numbers, mark requirements, modulating step instructions, api to add step instructions, and actually add the sop's, step video / image coordination : 8

## from tomorrow : chinese walls.

## today incorporate mark requirements in overflow hash, then 

## to do after june 7th

## chat : 2 days
## location : 2 days
## b2b site
## test object + guideline : 6 days
## integration into shopping cart : 3 days
## apis for symptom test, survey, animation and image : 4 days
## actual deployment


## first step is query
## then 
