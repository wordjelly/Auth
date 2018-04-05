require 'rails_helper'

RSpec.describe Auth::Workflow::Sop, type: :model, :sop_model => true do

	context " -- wrapper -- " do 

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

		context " -- create order flow -- " do 

			it " -- returns empty response if no sop's are found -- " do 
				
				cart_items_and_assembly = create_cart_items_assembly_sops_with_product_ids(@u,2,false)
				cart_items = cart_items_and_assembly[:cart_items]
				assembly = cart_items_and_assembly[:assembly]
				## it should have created two cart items.
				## fire the clone event, expect it to return the array of events searching for those sop's.
				## now clone with all the product ids in the arguments.
				options = {}
				options[:product_ids] = cart_items.map{|c| c = c.product_id.to_s}
				events = assembly.clone_to_add_cart_items(options)
				
				## so we want to call process on each of these events.
				events.each do |event|
					expect(event.process).to be_empty
				end

			end

			it " -- creates a series of events to mark the requirements if sops's are found -- " do 
				cart_items_and_assembly = create_cart_items_assembly_sops_with_product_ids(@u,2)
				cart_items = cart_items_and_assembly[:cart_items]
				assembly = cart_items_and_assembly[:assembly]
				## it should have created two cart items.
				## fire the clone event, expect it to return the array of events searching for those sop's.
				## now clone with all the product ids in the arguments.
				options = {}
				options[:product_ids] = cart_items.map{|c| c = c.product_id.to_s}
				events = assembly.clone_to_add_cart_items(options)
				
				## so we want to call process on each of these events.
				events.each do |event|
					expect(event.process).not_to be_empty
				end

			end

		end

	end

end