require "rails_helper"

RSpec.describe "assembly request spec",:assembly => true, :type => :request do 


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
				
				assembly = Auth::Workflow::Assembly.new(attributes_for(:assembly))
				assembly.stages = [Auth::Workflow::Stage.new]
				assembly.stages[0].name = "first stage"
				assembly.stages[0].sops = [Auth::Workflow::Sop.new]
				assembly.stages[0].sops[0].steps = [Auth::Workflow::Step.new]
				post assemblies_path, {assembly: assembly,:api_key => "test", :current_app_id => "testappid"}.to_json,@admin_headers
				expect(response.code).to eq("201")
				assembly_created = Auth::Workflow::Assembly.first
				expect(assembly_created.stages).to be_empty 
			end			
 
		end


		context " -- permissions -- " do 


				it " -- non admin user returns 422 -- " do 

					
					assembly = Auth::Workflow::Assembly.new(attributes_for(:assembly))
					assembly.stages = [Auth::Workflow::Stage.new]
					assembly.stages[0].name = "first stage"
					assembly.stages[0].sops = [Auth::Workflow::Sop.new]
					assembly.stages[0].sops[0].steps = [Auth::Workflow::Step.new]
					post assemblies_path, {assembly: assembly,:api_key => "test", :current_app_id => "testappid"}.to_json,@headers
					expect(response.code).to eq("422")					

				end


		end

		context " -- CRUD -- " do 

			## will do these later, they are not absoulutely critical.

			it  " -- can update name and description -- " do 
				
			end

			it " -- can delete the assembly -- " do 

			end
			
		end

	end

end