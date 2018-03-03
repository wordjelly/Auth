require "rails_helper"

RSpec.describe "sop request spec",:sop => true, :workflow => true, :type => :request do

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

		it " -- creates a sop given an assembly and a stage-- " do 
			assembly = create_empty_assembly
			stage = Auth::Workflow::Stage.new
			assembly.stages << stage
			assembly.save
			sop = attributes_for(:sop)
			sop[:assembly_id] = assembly.id.to_s
			sop[:assembly_doc_version] = assembly.doc_version
			sop[:stage_id] = stage.id.to_s
			sop[:stage_doc_version] = stage.doc_version
			sop[:stage_index] = 0
			post sops_path, {sop: sop,:api_key => "test", :current_app_id => "testappid"}.to_json,@admin_headers
			
			expect(response.code).to eq("201")
			assembly = Auth::Workflow::Assembly.find(assembly.id)
			expect(assembly.stages[0].sops[0].name).to eq(sop[:name])
		end

=begin
		it " -- creates a stage when one stage already exists -- " do 
			assembly = create_empty_assembly
			assembly.stages << Auth::Workflow::Stage.new
			assembly.save
			stage = attributes_for(:stage)
			stage[:assembly_id] = assembly.id.to_s
			stage[:assembly_doc_version] = assembly.doc_version
			post stages_path, {stage: stage,:api_key => "test", :current_app_id => "testappid"}.to_json,@admin_headers
			expect(response.code).to eq("201")
			assembly = Auth::Workflow::Assembly.find(assembly.id)
			expect(assembly.stages[1].name).to eq(stage[:name])
		end
=end

		it " -- updates an sop -- " do 
			assembly = create_empty_assembly
			stage = Auth::Workflow::Stage.new
			sop = Auth::Workflow::Sop.new
			stage.sops << sop
			assembly.stages << stage
			assembly.save

			## so now we need to update it.
			a = {:sop => {:name => "new_name",:description => "cat", :assembly_id => assembly.id.to_s, :assembly_doc_version => assembly.doc_version, :stage_index => 0, :stage_doc_version => stage.doc_version, :stage_id => stage.id.to_s, :doc_version => stage.doc_version, :sop_index => 0}, api_key: @ap_key, :current_app_id => "testappid"}
	            ##have to post to the id url.
	        put sop_path({:id => sop.id.to_s}), a.to_json,@admin_headers
	        #puts response.body.to_s
	        expect(response.code).to eq("204")
	        ## find the assembly and the first stage
	        assembly = Auth::Workflow::Assembly.find(assembly.id)
			expect(assembly.stages[0].sops[0].name).to eq("new_name")
			expect(assembly.stages[0].sops[0].doc_version).to eq(1)
		end

	end

end