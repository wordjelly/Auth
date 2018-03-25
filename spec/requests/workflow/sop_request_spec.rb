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

		context " -- create -- " do 

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

			it " -- does not create stage if orders have already been added -- " do 

				assembly = create_assembly_with_stage_sops_and_order
				expect(assembly.save).to be_truthy
				##now add a stage to this assembly.
				sop = attributes_for(:sop)
				sop[:assembly_id] = assembly.id.to_s
				sop[:assembly_doc_version] = assembly.doc_version
				sop[:stage_id] = assembly.stages[0].id.to_s
				sop[:stage_doc_version] = assembly.stages[0].doc_version
				sop[:stage_index] = 0
				post sops_path, {sop: sop,:api_key => "test", :current_app_id => "testappid"}.to_json,@admin_headers

				expect(response.code).to eq("422")

			end

		end

		context " -- update -- " do 



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



			

			it " -- does not update stage locked attributes if orders added -- ", :rabid => true do 

				assembly = create_assembly_with_stage_sops_and_order
				assembly.applicable = true
				assembly.stages[0].applicable = true
				assembly.stages[0].sops[0].applicable = true
				expect(assembly.save).to be_truthy
				stage = assembly.stages[0]
				## now just try to update the stage as not applicable.
				a = {:sop => {:applicable => false, :assembly_id => assembly.id.to_s, :assembly_doc_version => assembly.doc_version, :stage_index => 0, :stage_doc_version => stage.doc_version, :stage_id => stage.id.to_s, :doc_version => stage.doc_version, :sop_index => 0}, api_key: @ap_key, :current_app_id => "testappid"}
	            ##have to post to the id url.
		        put stage_path({:id => assembly.stages[0].id.to_s}), a.to_json,@admin_headers
		        expect(response.code).to eq("422")


			end
			


		end



		context " -- delete -- " do 

			
		end

		context " -- index -- ", :search_sop => true do 

			it " -- returns an array of applicable sop_ids, given an array of product_ids -- " do 

				assembly = Auth::Workflow::Assembly.new
				

				stage_one = Auth::Workflow::Stage.new
				stage_two = Auth::Workflow::Stage.new

				sop_one = Auth::Workflow::Sop.new
				sop_two = Auth::Workflow::Sop.new
				sop_three = Auth::Workflow::Sop.new
				sop_four = Auth::Workflow::Sop.new

				##########################################

				product_one = Auth::Shopping::Product.new
				product_one.resource_id = @u.id.to_s
				product_one.resource_class = @u.class.name.to_s
				product_one.signed_in_resource = @admin
				expect(product_one.save).to be_truthy

				##########################################

				product_two = Auth::Shopping::Product.new
				product_two.resource_id = @u.id.to_s
				product_two.resource_class = @u.class.name.to_s
				product_two.signed_in_resource = @admin
				expect(product_two.save).to be_truthy

				##########################################

				product_three = Auth::Shopping::Product.new
				product_three.resource_id = @u.id.to_s
				product_three.resource_class = @u.class.name.to_s
				product_three.signed_in_resource = @admin
				expect(product_three.save).to be_truthy

				##########################################

				sop_one.applicable_to_product_ids = [	
					product_two.id.to_s,product_three.id.to_s]

				sop_one.assembly_id = assembly.id.to_s

				sop_four.applicable_to_product_ids = [product_two.id.to_s,product_three.id.to_s]

				sop_two.applicable_to_product_ids = [product_one.id.to_s]

				stage_one.sops << sop_four

				stage_two.sops << sop_one

				stage_two.sops << sop_two

				assembly.stages << stage_one
				assembly.stages << stage_two

				expect(assembly.save).to be_truthy

				###########################################



				
				get sops_path({sop: sop_one.attributes.merge({:assembly_id => assembly.id.to_s}),:api_key => "test", :current_app_id => "testappid"}), nil,@admin_headers

				expect(response.code).to eq("200")

				## it should return sop_one and four.

				array_of_sops = JSON.parse(response.body)
				ids = array_of_sops.map{|c|
					c = Auth.configuration.sop_class.constantize.new(c)	
				}.map{|c| c = c.id.to_s}
				expect(ids.size).to eq(2)
				expect(ids.include? sop_one.id.to_s).to be_truthy
				expect(ids.include? sop_four.id.to_s).to be_truthy

			end

		end

		

	end

end

## ---------------------------------------------------------

## basic flow of events
## check which sop is applicable to products
## then call update on that sop with the products
## before_update -> call can_add
## that calls process_step on each step -> which in turn calls the functions in requirement to see if the requirements 

## if some products have already been added, then first attempt is to add the new product into the next sop to which it is applicable, and which is scheduled to be run.
## there if it cannot be added -> then we have to go to the checkpoint steps, and try to add it there -> if it can be added, then proceed to schedule it. otherwise keep going backwards, if you reach the root, then that's it.
