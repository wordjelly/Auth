require "rails_helper"

RSpec.describe "assembly request spec",:assembly => true, :workflow => true, :type => :request do 


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

	context " -- json requests -- " do 
		
		before(:example) do 
			Auth::Workflow::Assembly.delete_all
		end

		context " -- permitted_params -- " do 

			


			it "-- does not permit stages, sops or steps -- " do 
				
				assembly = create_assembly_with_stages_sops_and_steps
				post assemblies_path, {assembly: assembly,:api_key => "test", :current_app_id => "testappid"}.to_json,@admin_headers
				expect(response.code).to eq("201")
				assembly_created = Auth::Workflow::Assembly.first
				expect(assembly_created.stages).to be_empty 
			end			
 
		end


		context " -- permissions -- " do 


				it " -- non admin user returns 422 -- " do 

					
					assembly = create_assembly_with_stages_sops_and_steps
					post assemblies_path, {assembly: assembly,:api_key => "test", :current_app_id => "testappid"}.to_json,@headers
					expect(response.code).to eq("422")					

				end


		end

		context " -- CRUD -- " do 

			context " -- basic create -- " do 


			end

			context " -- clone creation -- " do 


				it " -- creates a copy of the latest created master assembly -- " do 


				end


				it " -- cannot set master attribute on create -- " do 


				end

			end


			context " -- orders added -- " do 



				it " -- cannot mark as master -- " do 


				end


				it " -- does not accept applicability changes -- " do 

				end


			end

			context " -- update -- " do 
					

				it  " -- can update this assembly as master from false to true -- " do 


				end


				it " -- cannot update master assembly id -- " do 


				end

				
				it  " -- can update name and description -- " do 
					assembly = create_assembly_with_stages_sops_and_steps
					res = assembly.save
					#puts "result of saving:"
					#puts res.to_s
					## we want to update name and description.
					a = {:assembly => {:name => "dog",:description => "cat"}, api_key: @ap_key, :current_app_id => "testappid"}
		            ##have to post to the id url.
		            put assembly_path({:id => assembly.id.to_s}), a.to_json,@admin_headers

		            expect(response.code).to eq("204")
		            #puts response.body.to_s
				end

				it " -- cannot update master from true to false -- " do 


				end

				it " -- can accept an array of stages,sops,steps,requirements,states to mark as applicable or not_applicable -- " do 


				end


			end

		end

	end

end