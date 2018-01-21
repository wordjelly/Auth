require "rails_helper"

RSpec.describe "search request spec",:search => true, :type => :request do 

	before(:all) do 
		ActionController::Base.allow_forgery_protection = false
        User.delete_all
        Auth::Client.delete_all
        Shopping::Product.delete_all
        @u = User.new(attributes_for(:user_confirmed))
        @u.versioned_create

        @c = Auth::Client.new(:resource_id => @u.id, :api_key => "test", :app_ids => ["test_app_id"])
        @c.redirect_urls = ["http://www.google.com"]
        @c.versioned_create
        @u.client_authentication["test_app_id"] = "test_es_token"
        @u.save
        @ap_key = @c.api_key
        @headers = { "CONTENT_TYPE" => "application/json" , "ACCEPT" => "application/json", "X-User-Token" => @u.authentication_token, "X-User-Es" => @u.client_authentication["test_app_id"], "X-User-Aid" => "test_app_id"}
        

        ### CREATE ONE ADMIN USER
        ### It will use the same client as the user.
        @admin = Admin.new(attributes_for(:admin_confirmed))
        @admin.client_authentication["test_app_id"] = "test_es_token"
        @admin.versioned_create
        @admin_headers = { "CONTENT_TYPE" => "application/json" , "ACCEPT" => "application/json", "X-Admin-Token" => @admin.authentication_token, "X-Admin-Es" => @admin.client_authentication["test_app_id"], "X-Admin-Aid" => "test_app_id"}
	end


	context " -- signed in user -- " do 

		context " -- public resource -- " do 
			
			before(:all) do 
				## create a product.
				@product = Shopping::Product.new
				@product.name = "Cobas e411"
				@product.price = 500.00
				@product.signed_in_resource = @admin
				@product.resource_id = @admin.id.to_s
				@product.resource_class = @admin.class.name.to_s
				sp = @product.save
				puts "product successfully saved: #{sp.to_s}"

			end

			it " -- allows user to search -- " do 
				get authenticated_user_search_index_path({api_key: @ap_key, :current_app_id => "test_app_id", query: {query_string: "Coba", size:10}}),nil,@headers

				results = JSON.parse(response.body)
				expect(results.size).to eq(1)
			end

			it " -- allows admin to search -- " do 
				get authenticated_user_search_index_path({api_key: @ap_key, :current_app_id => "test_app_id", query: {query_string: "Coba", size:10}}),nil,@admin_headers

				results = JSON.parse(response.body)
				expect(results.size).to eq(1)
			end
		end

		context " -- private resource -- " do 
			
			before(:all) do 
				@product = Shopping::Product.new
				@product.name = "Roche 423"
				@product.price = 500.00
				@product.signed_in_resource = @admin
				@product.resource_id = @admin.id.to_s
				@product.resource_class = @admin.class.name.to_s
				sp = @product.save
				puts "product successfully saved: #{sp.to_s}"
				## create a cart item.
				## using the product id as above.
				@cart_item = Shopping::CartItem.new
				@cart_item.product_id = @product.id.to_s
				@cart_item.resource_class = @u.class.name.to_s
				@cart_item.resource_id = @u.id.to_s
				@cart_item.signed_in_resource = @u
				su = @cart_item.save
				puts "cart item saved: #{su.to_s}"

				## create one more user who shouldnt be able to see this cart item.
				
			end

			it " -- allows user to search if he owns resource -- " do 



			end
			
			it " -- allows admin to search -- " do 

			end

		end

	end

	context " -- no signed in user -- " do 
		it " -- returns not authenticated -- " do 

		end
	end



end