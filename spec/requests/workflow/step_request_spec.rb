require "rails_helper"

RSpec.describe "step request spec",:step => true, :workflow => true, :type => :request do

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

		it " -- creates an empty step given an assembly and a stage and a sop " do 
			assembly = create_empty_assembly
			stage = Auth::Workflow::Stage.new
			sop = Auth::Workflow::Sop.new
			stage.sops << sop
			assembly.stages << stage
			res = assembly.save
			
			step = attributes_for(:step)
			step[:assembly_id] = assembly.id.to_s
			step[:assembly_doc_version] = assembly.doc_version
			step[:stage_id] = stage.id.to_s
			step[:stage_doc_version] = stage.doc_version
			step[:stage_index] = 0
			step[:sop_id] = sop.id.to_s
			step[:sop_doc_version] = sop.doc_version
			step[:sop_index] = 0

			post steps_path, {step: step,:api_key => "test", :current_app_id => "testappid"}.to_json,@admin_headers
			
			expect(response.code).to eq("201")
			assembly = Auth::Workflow::Assembly.find(assembly.id)
			expect(assembly.stages[0].sops[0].steps[0].name).to eq(step[:name])
		end


		it " -- does not create step if orders have already been added -- " do 

				assembly = create_assembly_with_stage_sops_and_order
				##now add a stage to this assembly.
				stage = assembly.stages[0]
				sop = assembly.stages[0].sops[0]

				step = attributes_for(:step)
				step[:assembly_id] = assembly.id.to_s
				step[:assembly_doc_version] = assembly.doc_version
				step[:stage_id] = stage.id.to_s
				step[:stage_doc_version] = stage.doc_version
				step[:stage_index] = 0
				step[:sop_id] = sop.id.to_s
				step[:sop_doc_version] = sop.doc_version
				step[:sop_index] = 0

				post steps_path, {step: step,:api_key => "test", :current_app_id => "testappid"}.to_json,@admin_headers

				expect(response.code).to eq("422")

		end


		it " -- updates step name,description given an assembly, stage, sop and step information -- " do 

			assembly = create_empty_assembly
			stage = Auth::Workflow::Stage.new
			sop = Auth::Workflow::Sop.new
			step = Auth::Workflow::Step.new
			sop.steps << step
			stage.sops << sop
			assembly.stages << stage
			res = assembly.save
			puts "result of saving: #{res.to_s}"

			a = {:step => {:name => "new_name",:description => "cat", :assembly_id => assembly.id.to_s, :assembly_doc_version => assembly.doc_version, :stage_index => 0, :stage_doc_version => stage.doc_version, :stage_id => stage.id.to_s, :doc_version => step.doc_version, :sop_index => 0, :sop_doc_version => sop.doc_version, :sop_id => sop.id.to_s, :step_index => 0}, api_key: @ap_key, :current_app_id => "testappid"}
	            ##have to post to the id url.
	        put step_path({:id => step.id.to_s}), a.to_json,@admin_headers

	        puts response.body.to_s
	        expect(response.code).to eq("204")

		end


		context " -- update -- " do 

			it  " -- does not update step locked attributes if orders have already been added -- " do 

				assembly = create_assembly_with_stage_sops_and_order
				assembly.applicable = true
				assembly.stages[0].applicable = true
				assembly.stages[0].sops[0].applicable = true
				assembly.stages[0].sops[0].steps << Auth::Workflow::Step.new
				assembly.stages[0].sops[0].steps[0].applicable = true
				expect(assembly.save).to be_truthy
				stage = assembly.stages[0]
				sop = assembly.stages[0].sops[0]
				step = assembly.stages[0].sops[0].steps[0]

				## now just try to update the stage as not applicable.
				a = {:step => {:applicable => false, :assembly_id => assembly.id.to_s, :assembly_doc_version => assembly.doc_version, :stage_index => 0, :stage_doc_version => stage.doc_version, :stage_id => stage.id.to_s, :doc_version => step.doc_version, :sop_index => 0, :sop_doc_version => sop.doc_version, :sop_id => sop.id.to_s, :step_index => 0}, api_key: @ap_key, :current_app_id => "testappid"}
	            ##have to post to the id url.
	        	put step_path({:id => step.id.to_s}), a.to_json,@admin_headers

	        	expect(response.code).to eq("422")

		    end
				
		end

		context " -- schedule sop order -- " do 

			it " -- modifies its own tlocation hash using the tlocation information supplied by the first cart_item -- " do 


			end

			it " -- resolves location ,if marked so -- " do 

			end


			it " -- resolves time , if marked so -- " do 

			end

			it " -- calculates duration , and appends duration since start -- " do 

			end

			

		end

	end

end




