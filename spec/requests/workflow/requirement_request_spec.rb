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

				## now we should post and expect create to succeed.
				
				puts "requirement attributes"
				puts requirement_attributes.to_s

				post requirements_path, {requirement: requirement_attributes,:api_key => "test", :current_app_id => "testappid"}.to_json,@admin_headers
			
				expect(response.code).to eq("201")

				



			end
		end


		context " -- update -- " do 
			it " -- updates a requirement given assembly, stage, sop, step and requirement index details -- " do 

			end
		end


		context " -- validations -- " do 

		end
		

	end


end