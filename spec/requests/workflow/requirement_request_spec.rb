require "rails_helper"

RSpec.describe "requirement request spec",:requirement => true, :workflow => true, :type => :request do

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

		context " -- create -- " do 
			it " -- creates a requirement given assembly, stage, sop, step details -- " do 
				
				assembly = create_assembly_with_stages_sops_and_steps
				
				expect(assembly.save).to be_truthy

				requirement_attributes = attributes_for(:requirement)

				add_assembly_info_to_object(assembly,requirement_attributes)

				add_stage_info_to_object(assembly,assembly.stages.first,requirement_attributes)

				add_sop_info_to_object(assembly,assembly.stages.first,assembly.stages.first.sops.first,requirement_attributes)

				add_step_info_to_object(assembly,assembly.stages.first,assembly.stages.first.sops.first,assembly.stages.first.sops.first.steps.first,requirement_attributes)

				
				post requirements_path, {requirement: requirement_attributes,:api_key => "test", :current_app_id => "testappid"}.to_json,@admin_headers
			
				expect(response.code).to eq("201")

			end

			it " -- does not create requirement if orders have been added to assembly -- " do 

				assembly = create_assembly_with_stages_sops_and_steps
				
				assembly.stages[0].sops[0].orders << Auth::Workflow::Order.new(:action => 1)

				expect(assembly.save).to be_truthy

				requirement_attributes = attributes_for(:requirement)

				add_assembly_info_to_object(assembly,requirement_attributes)

				add_stage_info_to_object(assembly,assembly.stages.first,requirement_attributes)

				add_sop_info_to_object(assembly,assembly.stages.first,assembly.stages.first.sops.first,requirement_attributes)

				add_step_info_to_object(assembly,assembly.stages.first,assembly.stages.first.sops.first,assembly.stages.first.sops.first.steps.first,requirement_attributes)

				
				post requirements_path, {requirement: requirement_attributes,:api_key => "test", :current_app_id => "testappid"}.to_json,@admin_headers
			
				expect(response.code).to eq("422")

			end

		end


		context " -- update -- " do 
			it " -- updates a requirement given assembly, stage, sop, step and requirement index details -- " do 

				assembly = create_assembly_with_stages_sops_steps_and_requirements
	
				requirement = assembly.stages[0].sops[0].steps[0].requirements[0]

				assembly.stages[0].sops[0].steps[0].requirements[0].name = "first requirement."

				expect(assembly.save).to be_truthy

				## now start adding shit into this.
				## we want to modify this requirement.
				## so we have to add the stage, index

				requirement_attributes = requirement.attributes

				add_assembly_info_to_object(assembly,requirement_attributes)

				add_stage_info_to_object(assembly,assembly.stages.first,requirement_attributes)

				add_sop_info_to_object(assembly,assembly.stages.first,assembly.stages.first.sops.first,requirement_attributes)

				add_step_info_to_object(assembly,assembly.stages.first,assembly.stages.first.sops.first,assembly.stages.first.sops.first.steps.first,requirement_attributes)

				add_requirement_info_to_object(assembly,assembly.stages.first,assembly.stages.first.sops.first,assembly.stages.first.sops.first.steps.first, assembly.stages.first.sops.first.steps.first.requirements.first,requirement_attributes)

				## now remove the 
				requirement_attributes.delete(:requirement_id)
				requirement_attributes[:doc_version] = requirement_attributes.delete(:requirement_doc_version)

				## now put the new name.
				requirement_attributes[:name] = "we changed the name"

				puts "the requirement attributes are:"
				puts requirement_attributes.to_s

				a = {:requirement => requirement_attributes, api_key: @ap_key, :current_app_id => "testappid"}
	            ##have to post to the id url.
		        put requirement_path({:id => requirement.id.to_s}), a.to_json,@admin_headers

		        puts response.body.to_s
		        expect(response.code).to eq("204")				

			end


			it " -- does not update locked attributes if orders have been added to the sop -- " do 

				assembly = create_assembly_with_stages_sops_steps_and_requirements

				assembly.stages[0].sops[0].orders[0] = Auth::Workflow::Order.new(:action => 1)
	
				requirement = assembly.stages[0].sops[0].steps[0].requirements[0]

				assembly.stages[0].sops[0].steps[0].requirements[0].name = "first requirement."

				assembly.stages[0].sops[0].steps[0].requirements[0].applicable = true

				expect(assembly.save).to be_truthy

				## now start adding shit into this.
				## we want to modify this requirement.
				## so we have to add the stage, index

				requirement_attributes = requirement.attributes

				add_assembly_info_to_object(assembly,requirement_attributes)

				add_stage_info_to_object(assembly,assembly.stages.first,requirement_attributes)

				add_sop_info_to_object(assembly,assembly.stages.first,assembly.stages.first.sops.first,requirement_attributes)

				add_step_info_to_object(assembly,assembly.stages.first,assembly.stages.first.sops.first,assembly.stages.first.sops.first.steps.first,requirement_attributes)

				add_requirement_info_to_object(assembly,assembly.stages.first,assembly.stages.first.sops.first,assembly.stages.first.sops.first.steps.first, assembly.stages.first.sops.first.steps.first.requirements.first,requirement_attributes)

				

				## now remove the 
				requirement_attributes.delete(:requirement_id)
				requirement_attributes[:doc_version] = requirement_attributes.delete(:requirement_doc_version)

				## now put the new name.
				#requirement_attributes[:name] = "we changed the name"

				requirement_attributes[:applicable] = false

				puts "the requirement attributes are:"
				puts requirement_attributes.to_s

				a = {:requirement => requirement_attributes, api_key: @ap_key, :current_app_id => "testappid"}
	            ##have to post to the id url.
		        put requirement_path({:id => requirement.id.to_s}), a.to_json,@admin_headers

		        puts response.body.to_s
		        expect(response.code).to eq("422")	



			end

		end

		context " -- schedule order -- " do 

			it " -- resolves location ,if marked so -- " do 

			end


			it " -- resolves time , if marked so -- " do 

			end

			it " -- adds the duration since the first step -- " do 

			end

			it " -- adds duration from step itself -- " do 


			end

			it " -- adds the requirement to the query hash to be queried -- " do 

			end

			it " -- calls build query -- " do 


			end

		end

	end


end