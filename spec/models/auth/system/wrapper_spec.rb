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


		context " -- query -- " do 

			context " -- time specifications -- " do 

				it " -- builds from spec, if it is the first step -- " do 

				end

				it " -- builds from previous if it is a subsequent step -- " do 
				end

			end

			context " -- location specifications -- " do 


			end

			it " -- does query and creates unit -- " do 

			end

			it " -- does another query and modifies query results in unit -- " do 

			end

			it " -- stores the query details in the overlap hash -- " do 

			end

		end



		context " -- process step, check in , and next step -- " do 


		end


		context " -- query backtrace -- " do 


		end


		context " -- update locations -- " do 


		end

	end

end
