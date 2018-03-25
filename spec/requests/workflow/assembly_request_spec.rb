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

				it " -- creates an assembly with name -- " do 

					assembly = attributes_for(:assembly)

					post assemblies_path, {assembly: assembly,:api_key => "test", :current_app_id => "testappid"}.to_json,@admin_headers

					expect(response.code).to eq("201")
					expect(Auth.configuration.assembly_class.constantize.all.count).to eq(1)

				end

			end

			context " -- clone creation -- " do 


				it " -- creates a copy of the latest created master assembly -- " do 

					## so first create an assembly
					## then update it as master
					## then clone it by passing in a master id.
					assembly = create_empty_assembly
					assembly.master = true
					expect(assembly.save).to be_truthy

					assembly_clone = create_empty_assembly
					assembly_clone.master_assembly_id = assembly.id.to_s

					post assemblies_path, {assembly: assembly_clone,:api_key => "test", :current_app_id => "testappid"}.to_json,@admin_headers

					expect(response.code).to eq("201")
					expect(Auth.configuration.assembly_class.constantize.all.count).to eq(2)

				end

				it " -- does not create if the assembly provided as master is not the latest one -- " do 

					assembly = create_empty_assembly
					assembly.master = true
					expect(assembly.save).to be_truthy

					sleep(1)

					assembly_two = create_empty_assembly
					assembly_two.master = true
					expect(assembly_two.save).to be_truthy


					assembly_clone = create_empty_assembly
					assembly_clone.master_assembly_id = assembly.id.to_s
					## now try to clone from one.
					post assemblies_path, {assembly: assembly_clone,:api_key => "test", :current_app_id => "testappid"}.to_json,@admin_headers

					expect(response.code).to eq("422")

				end

				it " -- ignores master attribute on create -- ", :rubiks => true do 

					## try to create an assembly directly with master as true
					assembly = attributes_for(:assembly)
					assembly[:name] = "don juan"
					assembly[:master] = true

					post assemblies_path, {assembly: assembly,:api_key => "test", :current_app_id => "testappid"}.to_json,@admin_headers

					expect(response.code).to eq("201")

					assembly_created = assigns(:model)
					## get this assembly.
					assembly_created = Auth.configuration.assembly_class.constantize.first
					puts assembly_created.attributes.to_s
					expect(assembly_created.master).not_to be_truthy

				end

			end


			context " -- orders added -- " do 

				before(:example) do 
					@assembly_with_order = create_assembly_with_stage_sops_and_order
					#puts "is it valid."
					#puts @assembly_with_order.valid?
					#puts @assembly_with_order.errors.full_messages.to_s
					save_response = @assembly_with_order.save
					puts save_response.to_s
				end

				it " -- cannot mark as master -- ", :mark_as_master do 
					 
					a = {:assembly => {:master => true, :doc_version => @assembly_with_order.doc_version}, api_key: @ap_key, :current_app_id => "testappid"}
		            
		            put assembly_path({:id => @assembly_with_order.id.to_s}), a.to_json,@admin_headers

		            puts "this is the response body."
		            puts response.body.to_s

		            expect(response.code).to eq("422")


				end


				it " -- does not accept applicability changes -- " do 

				end


			end

			context " -- update -- " do 
					

				it  " -- can update this assembly as master from false to true -- " do 


				end


				it " -- cannot update master assembly id -- " do 


				end

				
				it  " -- can update name and description -- ", :normal_update => true do 
					assembly = create_assembly_with_stages_sops_and_steps
					res = assembly.save
					puts "result of saving:"
					puts res.to_s
					## we want to update name and description.
					a = {:assembly => {:name => "dog",:description => "cat", :doc_version => assembly.doc_version}, api_key: @ap_key, :current_app_id => "testappid"}
		            ##have to post to the id url.
		            put assembly_path({:id => assembly.id.to_s}), a.to_json,@admin_headers

		            puts response.body.to_s
		            expect(response.code).to eq("204")
		            #
				end

				it " -- cannot update master from true to false -- " do 

					## create an assembly with master true.
					## now try to change it to false.
					
					assembly_created = create_assembly_with_stages_sops_and_steps
					
					assembly_created[:master] = true
					
					expect(assembly_created.save).to be_truthy
					
					## now try to update this as false.
					a = {:assembly => {:master => false, :doc_version => assembly_created.doc_version}, api_key: @ap_key, :current_app_id => "testappid"}

		            ##have to post to the id url.
		            put assembly_path({:id => assembly_created.id.to_s}), a.to_json,@admin_headers

		            puts response.body.to_s
		            
		            expect(response.code).to eq("422")	
		            
				end

				it " -- can accept an array of stages,sops,steps,requirements,states to mark as applicable or not_applicable -- " do 


				end


			end

		end

	end

end