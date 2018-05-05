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

				wrapper = create_from_file("/home/bhargav/Github/auth/spec/test_json_assemblies/system/1.json")
				expect(wrapper.address).to be_nil
				wrapper.levels.each_with_index {|l,lindex|
					expect(l.address).to eq("l#{lindex}")
					l.branches.each_with_index{|b,bindex|
						expect(b.address).to eq(l.address + ":b#{bindex}")
						b.definitions.each_with_index{|d,dindex|
							expect(d.address).to eq(b.address + ":d#{dindex}")
							d.creations.each_with_index{|c,cindex|
								expect(c.address).to eq(d.address + ":c#{cindex}")
							}
							d.units.each_with_index{|u,uindex|
								expect(u.address).to eq(d.address + ":u#{uindex}")
							}
						}
					}
				}
				
			end



		end

=begin
		context " -- adding of cart items -- " do 

			context " -- locates brance, defintion and creation -- " do 

				context " -- address provided -- " do 

				end

				context " -- address not provided -- " do 

					it  " -- wrapper finds level and branch with 	appropriate product category -- "

						

					do


					it " -- branch finds definition with appropriate product requirements -- " do 


					end


					it " -- definition finds correct creation -- " do 


					end
					
				end

			end

		end

		context " -- processes cart items one at a time -- " do 

		end


		context " -- query -- " do 

			it " -- stores the results -- " do 

			end

			it " -- merges results up each level -- " do 

			end

		end
=end
	end

end
