require 'rails_helper'

RSpec.describe Auth::System::Wrapper, type: :model, :merger_model => true do
  	

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

		context " -- populates empty merger hash -- " do 

			it " -- populates with a query result that has a single location in it -- " do 
				
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

				merger = Auth::System::Merger.new

				merger.populate_merger_hash_for_the_first_time(response,"first_query")

				#puts JSON.pretty_generate(merger.merger_hash)

			end

			it " -- populates with a query result that has multiple locations in it -- ", :multi_location => true do 

				## from the second location, also we want.
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
					},
					{
						"start_time_range_beginning" => 0,
						"start_time_range_end" => 100,
						"duration" => 500,
						"location_id" => BSON::ObjectId(lr("second_location")),
						"categories" => [
							{
								"category" => "a",
								"arrives_at_location_categories" => ["l1"],
								"transport_capacity" => 1
							}
						]
					}
				]

				response = get_transport_location_result(location_info_array,"5.json")

				response.each do |res|

				end

				merger = Auth::System::Merger.new

				merger.populate_merger_hash_for_the_first_time(response,"first_query")

				puts JSON.pretty_generate(merger.merger_hash)

				expect(merger.merger_hash.keys.size).to eq(1)
				expect(merger.merger_hash[1.to_s.to_sym][:first_query].keys.size).to eq(2)



			end

		end

		context " --- adds subsequent query results to prepopulated merger hash -- ", :two_hit => true do 

			it " -- simply adds the same result twice -- " do 

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

				first_query_response = get_transport_location_result(location_info_array,"6.json")

				merger = Auth::System::Merger.new

				merger.populate_merger_hash_for_the_first_time(first_query_response,"first_query")
				
				location_info_array = 
				[
					{
						"start_time_range_beginning" => 8,
						"start_time_range_end" => 100,
						"duration" => 10,
						"location_id" => BSON::ObjectId(lr("first_location")),
						"capacity" => 1,
						"categories" => [
							{
								"category" => "a"
							}
						]
					}
				]					

				second_query_response = Auth.configuration.location_class.constantize.find_entities_non_transport(location_info_array)
				
				## it has to carry an array of indices, in the result, that this location is applicable to .
				## "this location" implying -> the location in the targeted_query. 
				location_applicability_hash = {
					"5b04851f421aa910c46a01a2" => [0]
				}

				merger.add_query_result(second_query_response,"second_query","first_query",location_applicability_hash,0,100)				
				puts JSON.pretty_generate(merger.merger_hash)
				
				expect(merger.merger_hash.to_s).to eq('{:"1"=>{:first_query=>{:"5b04851f421aa910c46a01a2"=>{:combinations=>{:"5b04851f421aa910c46a01a2_1"=>"1"}}}}, :"20"=>{:second_query=>{:"5b04851f421aa910c46a01a2"=>{:combinations=>{:"5b04851f421aa910c46a01a2_1_5b04851f421aa910c46a01a2_20"=>20}}}}}')


			end			

		end


		context " -- makes combinations only of the first and the last minute that is found to be applicable in the subsequent query -- ", :makes_first_last_combination => true do 
				
			it " -- first does one query and for the subsequent query finds 4 different minutes which are applicable and only sets the combinations on the first and last of those minutes -- " do 

				location_info_array = 
				[
					{
						"start_time_range_beginning" => 0,
						"start_time_range_end" => 21,
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

				first_query_response = get_transport_location_result(location_info_array,"8.json")

				
				merger = Auth::System::Merger.new

				merger.populate_merger_hash_for_the_first_time(first_query_response,"first_query")

				location_info_array = 
				[
					{
						"start_time_range_beginning" => 200,
						"start_time_range_end" => 300,
						"duration" => 10,
						"location_id" => BSON::ObjectId(lr("first_location")),
						"capacity" => 1,
						"categories" => [
							{
								"category" => "a"
							}
						]
					}
				]		

				second_query_response = Auth.configuration.location_class.constantize.find_entities_non_transport(location_info_array)
				
				#second_query_response.each do |sr|
				#	puts JSON.pretty_generate(sr)
				#end

				## it has to carry an array of indices, in the result, that this location is applicable to .
				## "this location" implying -> the location in the targeted_query. 
				location_applicability_hash = {
					"5b04851f421aa910c46a01a2" => [0]
				}

				merger.add_query_result(second_query_response,"second_query","first_query",location_applicability_hash,0,208)

				puts JSON.pretty_generate(merger.merger_hash)		
				#expect(merger.merger_hash.to_s).to eq('{:"1"=>{:first_query=>{:"5b04851f421aa910c46a01a2"=>{:combinations=>{:"5b04851f421aa910c46a01a2_1"=>"1"}}}}, :"204"=>{:second_query=>{:"5b04851f421aa910c46a01a2"=>{:combinations=>{:"5b04851f421aa910c46a01a2_1_5b04851f421aa910c46a01a2_204"=>207}}}}}')


			end

			it " -- first does one query, then finds 10 minutes applicable in the second query, and in the third query, correctly opens and closes the combinations as it loops over all the minutes in the merger hash -- " do 


			end

		end


		context " -- closes combinations -- ", :closes_combinations => true do 

			it " -- does not add a combination that should have been closed -- " do 

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

				response = get_transport_location_result(location_info_array,"7.json")

				#response.each do |res|
				#	puts JSON.pretty_generate(res)
				#end

				merger = Auth::System::Merger.new

				merger.populate_merger_hash_for_the_first_time(response,"first_query")

				#puts JSON.pretty_generate(merger.merger_hash)

				## the second result, should be such that , it will have both these minutes added into it.

				location_info_array = 
				[
					{
						"start_time_range_beginning" => 8,
						"start_time_range_end" => 100,
						"duration" => 10,
						"location_id" => BSON::ObjectId(lr("first_location")),
						"capacity" => 1,
						"categories" => [
							{
								"category" => "a"
							}
						]
					}
				]					

				second_query_response = Auth.configuration.location_class.constantize.find_entities_non_transport(location_info_array)
				
				second_query_response.each do |ss|
					puts JSON.pretty_generate(ss)
				end
				## it has to carry an array of indices, in the result, that this location is applicable to .
				## "this location" implying -> the location in the targeted_query. 
				location_applicability_hash = {
					"5b04851f421aa910c46a01a2" => [0]
				}

				merger.add_query_result(second_query_response,"second_query","first_query",location_applicability_hash,0,100)				
				puts JSON.pretty_generate(merger.merger_hash)
							
				#expect(merger_hash)


			end

		end

		
	end
	
end
