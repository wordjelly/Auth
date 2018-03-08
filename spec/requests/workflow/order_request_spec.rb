require "rails_helper"

RSpec.describe "order request spec",:orders => true, :workflow => true, :type => :request do

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

		context " -- creates -- " do 

			it " -- validates if sop can accept the order -- " do 



			end

			it " -- validates action is present -- " do 
				

			end


			it " -- creates an order with product_ids given an assembly and a stage and a sop " do

				assembly = create_empty_assembly
				stage = Auth::Workflow::Stage.new
				sop = Auth::Workflow::Sop.new
				stage.sops << sop
				assembly.stages << stage
				res = assembly.save
				
				order = attributes_for(:order)
				order[:assembly_id] = assembly.id.to_s
				order[:assembly_doc_version] = assembly.doc_version
				order[:stage_id] = stage.id.to_s
				order[:stage_doc_version] = stage.doc_version
				order[:stage_index] = 0
				order[:sop_id] = sop.id.to_s
				order[:sop_doc_version] = sop.doc_version
				order[:sop_index] = 0

				post orders_path, {order: order,:api_key => "test", :current_app_id => "testappid"}.to_json,@admin_headers
				
				expect(response.code).to eq("201")
				assembly = Auth::Workflow::Assembly.find(assembly.id)
				expect(assembly.stages[0].sops[0].orders[0].name).to eq(order[:name])
			
			end

		end

		context " -- update -- " do 

			it " -- update route does not exist -- " do 

			end

		end

	end

end