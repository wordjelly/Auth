RSpec.describe Auth::Shopping::CartItem, type: :model, :cart_item_model => true do

	include ActiveJob::TestHelper

	context " -- wrapper -- " do 

		before(:all) do
			User.delete_all
			## create one non admin user
			@u = User.new(attributes_for(:user_confirmed))
	        @u.save
	        puts @u.errors.full_messages
	        @c = Auth::Client.new(:resource_id => @u.id, :api_key => "test", :app_ids => ["testappid"])
	        @c.redirect_urls = ["http://www.google.com"]
	        @c.versioned_create
	        @u.client_authentication["testappid"] = "testestoken"
	        @u.additional_login_param = "9561137096"
			@u.additional_login_param_status = 2
	        expect(@u.save).to be_truthy
	        @ap_key = @c.api_key
	        @headers = { "CONTENT_TYPE" => "application/json" , "ACCEPT" => "application/json", "X-User-Token" => @u.authentication_token, "X-User-Es" => @u.client_authentication["testappid"], "X-User-Aid" => "testappid"}
			## create one admin user.
			@admin = User.new(attributes_for(:admin_confirmed))
	        @admin.admin = true
	        @admin.client_authentication["testappid"] = "testestoken2"
	        @admin.save
	        @admin_headers = { "CONTENT_TYPE" => "application/json" , "ACCEPT" => "application/json", "X-User-Token" => @admin.authentication_token, "X-User-Es" => @admin.client_authentication["testappid"], "X-User-Aid" => "testappid"}
		end

		before(:example) do 
			
			clean_all_work_related_classes
			
		end

		it " -- schedules all communications for delivery when accepted is set to true -- " do 

			#CommunicationJob.queue_adapter = :test

			product = Auth.configuration.product_class.constantize.new(JSON.parse(IO.read("#{Dir.pwd}/spec/models/auth/shopping/product.json")))
			product.signed_in_resource = @admin
			product.resource_class = @admin.class
			product.resource_id = @admin.id.to_s
			expect(product.save).to be_truthy

			cart_item = Auth.configuration.cart_item_class.constantize.new(product_id: product.id.to_s)
			cart_item.resource_class = @u.class
			cart_item.resource_id = @u.id.to_s
			cart_item.signed_in_resource = @u
			
			expect(cart_item.save).to be_truthy
			cart_item.accepted = true
			cart_item.parent_id = "test"
			

			#perform_enqueued_jobs do 
			cart_item.save	
			#end


			expect(ActionMailer::Base.deliveries.count).to eq(1)

		end

		it " -- schedules the repeat after 1 month -- ", :schedule_repeat => true do 

			
			product = Auth.configuration.product_class.constantize.new(JSON.parse(IO.read("#{Dir.pwd}/spec/models/auth/shopping/product.json")))
			product.signed_in_resource = @admin
			product.resource_class = @admin.class
			product.resource_id = @admin.id.to_s
			product.instructions.first.communications.first.repeat = "Monthly"
			product.instructions.first.communications.first.repeat_times = 1
			expect(product.save).to be_truthy

			cart_item = Auth.configuration.cart_item_class.constantize.new(product_id: product.id.to_s)
			cart_item.resource_class = @u.class
			cart_item.resource_id = @u.id.to_s
			cart_item.signed_in_resource = @u
			
			expect(cart_item.save).to be_truthy
			cart_item.accepted = true
			cart_item.parent_id = "test"

			
			
			cart_item.save	
			

			## expect the repeated count to be 1.
			cart_item = Auth.configuration.cart_item_class.constantize.find(cart_item.id.to_s)
			expect(cart_item.instructions.first.communications.first.repeated_times).to eq(1)

		end






	end
end

