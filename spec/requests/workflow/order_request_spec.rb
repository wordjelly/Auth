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

			it " -- creates an order with product_ids given an assembly and a stage and a sop " do

				assembly = create_empty_assembly
				stage = Auth::Workflow::Stage.new
				sop = Auth::Workflow::Sop.new
				stage.sops << sop
				assembly.stages << stage
				res = assembly.save
				
				order = attributes_for(:add_order)
				order[:cart_item_ids] = [BSON::ObjectId.new.to_s, BSON::ObjectId.new.to_s]
				order[:assembly_id] = assembly.id.to_s
				order[:assembly_doc_version] = assembly.doc_version
				order[:stage_id] = stage.id.to_s
				order[:stage_doc_version] = stage.doc_version
				order[:stage_index] = 0
				order[:sop_id] = sop.id.to_s
				order[:sop_doc_version] = sop.doc_version
				order[:sop_index] = 0

				post orders_path, {order: order,:api_key => "test", :current_app_id => "testappid"}.to_json,@admin_headers
				
				puts response.body.to_s
				expect(response.code).to eq("201")
				assembly = Auth.configuration.assembly_class.constantize.find(assembly.id)
				expect(assembly.stages[0].sops[0].orders.size).to eq(1)

			end


			it " -- does not create order if the cart items in it are already there in a previous order -- " do 

				## first create one order,
				## then try to create another order with the same cart_item_ids.
				## okays so lets go.
				assembly = create_empty_assembly
				stage = Auth::Workflow::Stage.new
				sop = Auth::Workflow::Sop.new
				stage.sops << sop
				assembly.stages << stage
				res = assembly.save
				first_order = create_order_into_sop(assembly,stage,sop)
				raise unless first_order
				## now try to create another order in the same sop with these cart items.
				## it should not go through.
				order = Auth.configuration.order_class.constantize.new(:cart_item_ids => first_order.cart_item_ids)

				order[:assembly_id] = assembly.id.to_s
				order[:assembly_doc_version] = assembly.doc_version
				order[:stage_id] = stage.id.to_s
				order[:stage_doc_version] = stage.doc_version
				order[:stage_index] = 0
				order[:sop_id] = sop.id.to_s
				order[:sop_doc_version] = sop.doc_version
				order[:sop_index] = 0
				order[:action] = 1

				## post it .
				## it should fail.
				post orders_path, {order: order,:api_key => "test", :current_app_id => "testappid"}.to_json,@admin_headers
			
				puts response.body.to_s
				expect(response.code).to eq("422")

			end


			it " -- creates additional orders if the cart item ids are not already present in previous orders of the sop -- ", :double => true do 


				## first create one order,
				## then try to create another order with the same cart_item_ids.
				## okays so lets go.
				assembly = create_empty_assembly
				stage = Auth::Workflow::Stage.new
				sop = Auth::Workflow::Sop.new
				stage.sops << sop
				assembly.stages << stage
				res = assembly.save
				first_order =  create_order_into_sop(assembly,stage,sop)

				raise unless first_order

				puts "previous order cart item ids: #{first_order.cart_item_ids.to_s}"

				## create another order.
				order_new = attributes_for(:add_order)
				order_new[:cart_item_ids] = [BSON::ObjectId.new.to_s, BSON::ObjectId.new.to_s]
				puts "the order new is: #{order_new.to_s}"
				order_new[:assembly_id] = assembly.id.to_s
				order_new[:assembly_doc_version] = assembly.doc_version
				order_new[:stage_id] = stage.id.to_s
				order_new[:stage_doc_version] = stage.doc_version
				order_new[:stage_index] = 0
				order_new[:sop_id] = sop.id.to_s
				order_new[:sop_doc_version] = sop.doc_version
				order_new[:sop_index] =	 0

				

				post orders_path, {order: order_new,:api_key => "test", :current_app_id => "testappid"}.to_json,@admin_headers
				
				
				expect(response.code).to eq("201")
				assembly = Auth.configuration.assembly_class.constantize.find(assembly.id)
				expect(assembly.stages[0].sops[0].orders.size).to eq(2)					

			end

		end


	end

end