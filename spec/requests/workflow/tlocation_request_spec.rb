require "rails_helper"

RSpec.describe "tlocation request spec",:tlocation => true, :workflow => true, :type => :request do

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
			it " -- creates a tlocation given assembly, stage, sop, step details -- " do 
				
				assembly = create_assembly_with_stages_sops_and_steps
				
				expect(assembly.save).to be_truthy

				tlocation_attributes = attributes_for(:tlocation)
				tlocation_attributes[:product_id] = BSON::ObjectId.new.to_s

				add_assembly_info_to_object(assembly,tlocation_attributes)

				add_stage_info_to_object(assembly,assembly.stages.first,tlocation_attributes)

				add_sop_info_to_object(assembly,assembly.stages.first,assembly.stages.first.sops.first,tlocation_attributes)

				add_step_info_to_object(assembly,assembly.stages.first,assembly.stages.first.sops.first,assembly.stages.first.sops.first.steps.first,tlocation_attributes)

				
				post tlocations_path, {tlocation: tlocation_attributes,:api_key => "test", :current_app_id => "testappid"}.to_json,@admin_headers
			
				expect(response.code).to eq("201")

			end

			it " -- does not create tlocation if orders have been added to assembly -- " do 

				assembly = create_assembly_with_stages_sops_and_steps
				
				assembly.stages[0].sops[0].orders << Auth::Workflow::Order.new(:action => 1)

				expect(assembly.save).to be_truthy

				tlocation_attributes = attributes_for(:tlocation)
				tlocation_attributes[:product_id] = BSON::ObjectId.new.to_s

				add_assembly_info_to_object(assembly,tlocation_attributes)

				add_stage_info_to_object(assembly,assembly.stages.first,tlocation_attributes)

				add_sop_info_to_object(assembly,assembly.stages.first,assembly.stages.first.sops.first,tlocation_attributes)

				add_step_info_to_object(assembly,assembly.stages.first,assembly.stages.first.sops.first,assembly.stages.first.sops.first.steps.first,tlocation_attributes)

				
				post tlocations_path, {tlocation: tlocation_attributes,:api_key => "test", :current_app_id => "testappid"}.to_json,@admin_headers
			
				expect(response.code).to eq("422")

			end

		end


		context " -- update -- " do 
			it " -- updates a tlocation given assembly, stage, sop, step and tlocation index details -- " do 

				assembly = create_assembly_with_stages_sops_steps_and_tlocations
	
				tlocation = assembly.stages[0].sops[0].steps[0].tlocations[0]

				assembly.stages[0].sops[0].steps[0].tlocations[0].name = "first tlocation."

				assembly.stages[0].sops[0].steps[0].tlocations[0].product_id = BSON::ObjectId.new.to_s

				expect(assembly.save).to be_truthy

				## now start adding shit into this.
				## we want to modify this tlocation.
				## so we have to add the stage, index

				tlocation_attributes = tlocation.attributes

				add_assembly_info_to_object(assembly,tlocation_attributes)

				add_stage_info_to_object(assembly,assembly.stages.first,tlocation_attributes)

				add_sop_info_to_object(assembly,assembly.stages.first,assembly.stages.first.sops.first,tlocation_attributes)

				add_step_info_to_object(assembly,assembly.stages.first,assembly.stages.first.sops.first,assembly.stages.first.sops.first.steps.first,tlocation_attributes)

				add_tlocation_info_to_object(assembly,assembly.stages.first,assembly.stages.first.sops.first,assembly.stages.first.sops.first.steps.first, assembly.stages.first.sops.first.steps.first.tlocations.first,tlocation_attributes)

				## now remove the 
				tlocation_attributes.delete(:tlocation_id)
				tlocation_attributes[:doc_version] = tlocation_attributes.delete(:tlocation_doc_version)

				## now put the new name.
				tlocation_attributes[:name] = "we changed the name"

				puts "the tlocation attributes are:"
				puts tlocation_attributes.to_s

				a = {:tlocation => tlocation_attributes, api_key: @ap_key, :current_app_id => "testappid"}
	            ##have to post to the id url.
		        put tlocation_path({:id => tlocation.id.to_s}), a.to_json,@admin_headers

		        puts response.body.to_s
		        expect(response.code).to eq("204")				

			end


			it " -- does not update locked attributes if orders have been added to the sop -- " do 

				assembly = create_assembly_with_stages_sops_steps_and_tlocations

				assembly.stages[0].sops[0].orders[0] = Auth::Workflow::Order.new(:action => 1)
	
				tlocation = assembly.stages[0].sops[0].steps[0].tlocations[0]

				assembly.stages[0].sops[0].steps[0].tlocations[0].name = "first tlocation."

				assembly.stages[0].sops[0].steps[0].tlocations[0].product_id = BSON::ObjectId.new

				assembly.stages[0].sops[0].steps[0].tlocations[0].applicable = true

				expect(assembly.save).to be_truthy

				## now start adding shit into this.
				## we want to modify this tlocation.
				## so we have to add the stage, index

				tlocation_attributes = tlocation.attributes

				add_assembly_info_to_object(assembly,tlocation_attributes)

				add_stage_info_to_object(assembly,assembly.stages.first,tlocation_attributes)

				add_sop_info_to_object(assembly,assembly.stages.first,assembly.stages.first.sops.first,tlocation_attributes)

				add_step_info_to_object(assembly,assembly.stages.first,assembly.stages.first.sops.first,assembly.stages.first.sops.first.steps.first,tlocation_attributes)

				add_tlocation_info_to_object(assembly,assembly.stages.first,assembly.stages.first.sops.first,assembly.stages.first.sops.first.steps.first, assembly.stages.first.sops.first.steps.first.tlocations.first,tlocation_attributes)

				## now remove the 
				tlocation_attributes.delete(:tlocation_id)
				tlocation_attributes[:doc_version] = tlocation_attributes.delete(:tlocation_doc_version)

				## now put the new name.
				#tlocation_attributes[:name] = "we changed the name"

				tlocation_attributes[:applicable] = false

				puts "the tlocation attributes are:"
				puts tlocation_attributes.to_s

				a = {:tlocation => tlocation_attributes, api_key: @ap_key, :current_app_id => "testappid"}
	            ##have to post to the id url.
		        put tlocation_path({:id => tlocation.id.to_s}), a.to_json,@admin_headers

		        puts response.body.to_s
		        expect(response.code).to eq("422")	



			end

		end


		context " -- validations -- " do 

		end
		

	end


end