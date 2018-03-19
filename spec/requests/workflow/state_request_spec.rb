require "rails_helper"

RSpec.describe "state request spec",:state => true, :workflow => true, :type => :request do

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
			it " -- creates a state given assembly, stage, sop, step details -- ", :state_create => true do 
				
				assembly = create_assembly_with_stages_sops_steps_and_requirements
				
				expect(assembly.save).to be_truthy

				state_attributes = attributes_for(:state)

				add_assembly_info_to_object(assembly,state_attributes)

				add_stage_info_to_object(assembly,assembly.stages.first,state_attributes)

				add_sop_info_to_object(assembly,assembly.stages.first,assembly.stages.first.sops.first,state_attributes)

				add_step_info_to_object(assembly,assembly.stages.first,assembly.stages.first.sops.first,assembly.stages.first.sops.first.steps.first,state_attributes)

				add_requirement_info_to_object(assembly,assembly.stages.first,assembly.stages.first.sops.first,assembly.stages.first.sops.first.steps.first,assembly.stages.first.sops.first.steps.first.requirements.first,state_attributes)

				puts "the state attributes are:"
				puts state_attributes.to_s
				
				post states_path, {state: state_attributes,:api_key => "test", :current_app_id => "testappid"}.to_json,@admin_headers
				

				puts response.body.to_s

				expect(response.code).to eq("201")

			end
		end


		context " -- update -- " do 
			it " -- updates a state given assembly, stage, sop, step and state index details -- " do 

				assembly = create_assembly_with_stages_sops_steps_requirements_and_states
	
				state = assembly.stages[0].sops[0].steps[0].requirements[0].states[0]

				assembly.stages[0].sops[0].steps[0].requirements[0].states[0].name = "first state."

				expect(assembly.save).to be_truthy

				## now start adding shit into this.
				## we want to modify this state.
				## so we have to add the stage, index

				state_attributes = state.attributes

				add_assembly_info_to_object(assembly,state_attributes)

				add_stage_info_to_object(assembly,assembly.stages.first,state_attributes)

				add_sop_info_to_object(assembly,assembly.stages.first,assembly.stages.first.sops.first,state_attributes)

				add_step_info_to_object(assembly,assembly.stages.first,assembly.stages.first.sops.first,assembly.stages.first.sops.first.steps.first,state_attributes)


				add_requirement_info_to_object(assembly,assembly.stages.first,assembly.stages.first.sops.first,assembly.stages.first.sops.first.steps.first, assembly.stages.first.sops.first.steps.first.requirements.first,state_attributes)

				add_state_info_to_object(assembly,
					assembly.stages.first,
					assembly.stages.first.sops.first,
					assembly.stages.first.sops.first.steps.first,
					 assembly.stages.first.sops.first.steps.first.requirements.first,
					 assembly.stages.first.sops.first.steps.first.requirements.first.states.first,
					 state_attributes)

				## now remove the 
				state_attributes.delete(:state_id)
				state_attributes[:doc_version] = state_attributes.delete(:state_doc_version)

				## now put the new name.
				state_attributes[:name] = "we changed the name"

				puts "the state attributes are:"
				puts state_attributes.to_s

				a = {:state => state_attributes, api_key: @ap_key, :current_app_id => "testappid"}
	            ##have to post to the id url.
		        put state_path({:id => state.id.to_s}), a.to_json,@admin_headers

		        puts response.body.to_s
		        expect(response.code).to eq("204")				

			end
		end


		context " -- validations -- " do 

		end
		

	end


end