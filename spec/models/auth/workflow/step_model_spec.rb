require 'rails_helper'
RSpec.describe Auth::Workflow::Step, type: :model, :step_model => true do

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

=begin
	context " -- resolve time specs -- " do

		context " -- start_time_specifications present -- " do 

			it " -- raises error if minimum time since previous step missing -- " do 

				s = Auth.configuration.step_class.constantize.new
				s.applicable = true
				s.duration = 300
				s.time_information = {}
				s.time_information[:start_time_specification] = []
				expect {s.resolve_time(nil)}.to raise_error("minimum time since previous step is absent")	

			end

			context " -- previous step time information is provided -- " do 

				it " -- start time specification is not fulfilled, so throws an error -- " do 
					## 0 -> sunday, 1 -> monday, 2 -> tuesday, 3 -> wednesday, 4 -> thursday
					## lets give a start time specification which says thursday of any month in 2012.
					## and lets have an end time of the previous step so that it comes on a wednesday.
					s = Auth.configuration.step_class.constantize.new
					s.applicable = true
					s.duration = 300
					s.time_information = {}
					## basically any thursday of any year or month, from 12 am to 11.58:20 pm.
					s.time_information[:start_time_specification] = [["*","*","4","0","86300"]]
					s.time_information[:minimum_time_since_previous_step] = 0

					## now let us say the previous step time information
					## we want it to end on a friday.
					## so that it wont be accepted here.

					previous_step_time_information = {:start_time_range => [Time.new(2018,04,04).to_i, Time.new(2018,04,05).to_i], :end_time_range => [Time.new(2018,04,12,02,02).to_i, Time.new(2018,04,13,02,02).to_i]}


					expect {s.resolve_time(previous_step_time_information)}.to raise_error("does not satisfy the start time specification")


				end


				it " -- start time specification is fulfilled, so start time becomes end time of previous step + minimum time since previous step, and end time becomes start_time + duration -- " do 

					
					s = Auth.configuration.step_class.constantize.new

					s.applicable = true

					s.duration = 300

					s.time_information = {}
					
					s.time_information[:start_time_specification] = [["*","*","4","0","86300"]]

					s.time_information[:minimum_time_since_previous_step] = 0

					previous_step_time_information = {:start_time_range => [Time.new(2018,04,04).to_i, Time.new(2018,04,05).to_i], :end_time_range => [Time.new(2018,04,12,02,02).to_i, Time.new(2018,04,12,05,02).to_i]}

					s.resolve_time(previous_step_time_information)

					
					expect(s.time_information[:start_time_range]).to eq(previous_step_time_information[:end_time_range])

					expect(s.time_information[:end_time_range]).to eq(previous_step_time_information[:end_time_range].map{|c| c = c + s.duration})


				end


			end


			context " -- previous step time information is not provided -- " do 

				it " -- assigns the variables to the specification from the present time -- " do 

					s = Auth.configuration.step_class.constantize.new

					s.applicable = true

					s.duration = 300

					s.time_information = {}
					
					s.time_information[:start_time_specification] = [["*","*","4","0","86300"]]

					s.time_information[:minimum_time_since_previous_step] = 0

					s.resolve_time(nil)


					time_instance_to_consider = Time.now
					ymd = []
					ymd[0] = time_instance_to_consider.strftime("%Y")
					ymd[1] = time_instance_to_consider.strftime("%-m")
					ymd[2] = time_instance_to_consider.strftime("%w")

					beginning_of_day = DateTime.strptime(ymd.join(" "), '%Y %m %w')

					expect(s.time_information[:start_time_range]).to eq([beginning_of_day.to_i,beginning_of_day.to_i + 86300])


				end

			end

		end

		context " -- start_time specifications absent - " do

			context " -- previous step time specifications present -- " do 

				it " -- sets the start time range equal to the previous step end time range + the minimum time since the previou step -- " do 

					## so here we create a step
					## we give it some time information
					## and do from there.
					s = Auth.configuration.step_class.constantize.new
					s.applicable = true
					s.duration = 300
					previous_step_time_information = {:start_time_range => [Time.now - 5.days, Time.now - 4.days], :end_time_range => [Time.now - 3.days, Time.now - 4.days]}

					s.resolve_time(previous_step_time_information)
					## it should set the start_time + minimum time since previous step ?
					expect(s.time_information[:start_time_range]).to eq(previous_step_time_information[:end_time_range])

					expect(s.time_information[:end_time_range]).to eq(s.time_information[:start_time_range].map{|c| c = c + s.duration})

				end

			
			end

			context " -- previous step time specifications absent -- " do

				it " -- throws an error -- " do 

					s = Auth.configuration.step_class.constantize.new
					s.applicable = true
					s.duration = 300
					expect {s.resolve_time(nil)}.to raise_error("previous step time information absent")

				end

			end

		end


	end
	NOT APPLICABLE ANYMORE.
=end
	

	context " -- merge_cart_item_specifications -- " do 

		before(:example) do 
			Auth.configuration.location_class.constantize.delete_all
			Auth.configuration.cart_item_class.constantize.delete_all
			Auth.configuration.product_class.constantize.delete_all
		end

		context " -- one cart item  -- " do 

			context " -- no specification for cart item -- " do 

				it " -- return empty hash -- " do 
					step = Auth.configuration.step_class.constantize.new
					step.stage_index = 0
					step.sop_index = 0
					step.step_index = 0
					cart_items = load_cart_items_from_json("/home/bhargav/Github/auth/spec/test_json_assemblies/steps/1.json")
					expect(step.merge_cart_item_specifications(cart_items)).to be_empty
				end

			end

			context " -- cart item has specification -- " do 

				context " -- time specification present -- " do 

					context " -- time speficiation already exists -- " do 

						it " -- adds the cart item to existing time spec -- ", :tru_test => true do 


								step = Auth.configuration.step_class.constantize.new
								step.stage_index = 0
								step.sop_index = 0
								step.step_index = 0
								cart_items = load_cart_items_from_json("/home/bhargav/Github/auth/spec/test_json_assemblies/steps/4.json")
								response = step.merge_cart_item_specifications(cart_items) 
								expect(response).not_to be_empty
								expect(response.keys.size).to eq(1)
								expect(response.values.first.keys).to eq([:sort_key, :start_time_range, :any_location])
								puts JSON.pretty_generate(response)
								## expect there to be two cart item ids.
								expect(response.values.first[:any_location][:cart_item_ids].size).to eq(2)


						end

					end

					context " -- time specification new -- " do 

						context " -- no location specification -- " do 

							it " -- returns a hash with one key i.e the time specification --  " do 

								step = Auth.configuration.step_class.constantize.new
								step.stage_index = 0
								step.sop_index = 0
								step.step_index = 0
								cart_items = load_cart_items_from_json("/home/bhargav/Github/auth/spec/test_json_assemblies/steps/2.json")
								response = step.merge_cart_item_specifications(cart_items) 
								expect(response).not_to be_empty
								expect(response.keys.size).to eq(1)
								expect(response.values.first.keys).to eq([:sort_key, :start_time_range, :any_location])

							end

						end

						context " -- has location specification -- " do 

							it " -- returns hash with cart item as the single key, and time range with location spec  -- ", :loc_test => true do 

								step = Auth.configuration.step_class.constantize.new
								step.stage_index = 0
								step.sop_index = 0
								step.step_index = 0
								cart_items = load_cart_items_from_json("/home/bhargav/Github/auth/spec/test_json_assemblies/steps/3.json")
								response = step.merge_cart_item_specifications(cart_items) 

								expect(response).not_to be_empty
								expect(response.keys.size).to eq(1)
								
								response.values.first.keys.each do |k|
									if k.to_s == "start_time_range"
									elsif k.to_s == "sort_key"
									elsif k.to_s == "any_location"
									else
										## here we expect to see the location ids.
										expect(response.values.first[k].keys).to eq([:location,:cart_item_ids])
									end
								end


							end

						end

					end

					context " -- some items have only location specifications -- " do 

						it " -- a time specification has the same location as the those items which have only location specifications, so it adds the cart items to that time spec, loc spec.  -- ", :five => true do 

							step = Auth.configuration.step_class.constantize.new
							step.stage_index = 0
							step.sop_index = 0
							step.step_index = 0
							cart_items = load_cart_items_from_json("/home/bhargav/Github/auth/spec/test_json_assemblies/steps/5.json")
							response = step.merge_cart_item_specifications(cart_items) 
							response.values.first.keys.each do |v|
								if v.to_s == "sort_key"
								elsif v.to_s == "start_time_range"
								elsif v.to_s == "any_location"
								else
									expect(response.values.first[v][:cart_item_ids].size).to eq(2)
								end
							end
						end

					end

					context " -- some items have a location specification, but it does not match any of the location specifications in the time specifications that already exists -- " do 

						it " -- adds them to the earliest time specification -- " do 

							step = Auth.configuration.step_class.constantize.new
							step.stage_index = 0
							step.sop_index = 0
							step.step_index = 0
							cart_items = load_cart_items_from_json("/home/bhargav/Github/auth/spec/test_json_assemblies/steps/6.json")
							response = step.merge_cart_item_specifications(cart_items)
							
							## this should get added to the earliest time range.
							## so the first item should have 
							puts JSON.pretty_generate(response)

						end

					end

				end

			end		

		end

	end

	context " -- query -- " do 
		## how to test this in the first place.
		## basically the start time range is defined
		## if location ids are provided then they can be used -> in the basic find_entity query.
		## so first let us have those options provided in the find_entity query.
		## and what is the required return type
		## thereafter, it will look at the earliest and latest ranges.
		## if an origin location is provided, and there is a within radius and location categories, then they can also be provided, the speed part is optional.
	end
	

end