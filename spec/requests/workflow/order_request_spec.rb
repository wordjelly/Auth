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

			it " -- does not create order if assembly is master -- " do 
								
			end

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


		context " -- update -- ", :order_update => true do 

			it " -- updates the order , given assembly, stage, sop and order information -- " do 

				## create an assembly with stage, sop and order
				assembly = create_assembly_with_stage_sops_and_order

				## then update it.	
				assembly.stages[0].sops[0].orders[0].name = "initial name"
				assembly.stages[0].sops[0].orders[0].cart_item_ids = [BSON::ObjectId.to_s, BSON::ObjectId.to_s]
				assembly.stages[0].sops[0].orders[0].action = 1

				res = assembly.save

				expect(res).to be_truthy

				## now we need a newer 
				order_attributes = attributes_for(:add_order)

				##############################################

				add_assembly_info_to_object(assembly,order_attributes)

				add_stage_info_to_object(assembly,assembly.stages.first,order_attributes)

				add_sop_info_to_object(assembly,assembly.stages.first,assembly.stages.first.sops.first,order_attributes)

				add_order_info_to_object(assembly,assembly.stages.first,assembly.stages.first.sops.first,assembly.stages.first.sops.first.orders.first,order_attributes)


				## now remove the 
				order_attributes.delete(:order_id)
				order_attributes[:doc_version] = order_attributes.delete(:order_doc_version)

				## now put the new name.
				order_attributes[:name] = "we changed the name"
				order_attributes[:cart_item_ids] = [BSON::ObjectId.to_s,BSON::ObjectId.to_s]

				puts "the order attributes are:"
				puts order_attributes.to_s


				##############################################


				a = {:order => order_attributes, api_key: @ap_key, :current_app_id => "testappid"}
	            
	            ##have to post to the id url.
		        put order_path({:id => assembly.stages[0].sops[0].orders[0].id.to_s}), a.to_json,@admin_headers

		        puts response.body.to_s
		        expect(response.code).to eq("204")	


			end



			it " -- cannot update order action, for eg from process to don't process -- " do 


			end

		end

	end

end