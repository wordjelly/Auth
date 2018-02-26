require "rails_helper"

RSpec.describe "search request spec",:search => true, :type => :request do 

	before(:all) do 
		ActionController::Base.allow_forgery_protection = false
        User.delete_all
        Auth::Client.delete_all
        Shopping::Product.delete_all
        Shopping::CartItem.delete_all

        puts "deleting user index #{User.es.index.delete}"
        puts "creating user index: #{User.es.index.create}"


        puts "deleting product index #{Shopping::Product.es.index.delete}"
        puts "creating product index: #{Shopping::Product.es.index.create}"


        puts "deleting cart_item index #{Shopping::CartItem.es.index.delete}"

        puts "creating cart_item index: #{Shopping::CartItem.es.index.create}"


        ## CREATE A USER
        @u = User.new(attributes_for(:user_confirmed))
        @u.versioned_create

        @c = Auth::Client.new(:resource_id => @u.id, :api_key => "test", :app_ids => ["testappid"])
        @c.redirect_urls = ["http://www.google.com"]
        @c.versioned_create
        @u.client_authentication["testappid"] = "testestoken"
        @u.confirm!
        sr = @u.save
        @ap_key = @c.api_key
        @headers = { "CONTENT_TYPE" => "application/json" , "ACCEPT" => "application/json", "X-User-Token" => @u.authentication_token, "X-User-Es" => @u.client_authentication["testappid"], "X-User-Aid" => "testappid"}
        

        ### CREATE ONE ADMIN USER
        puts "---------------------------------------------------------------CREATING ADMIN-----------------------------------------"
        @admin = User.new(attributes_for(:admin_confirmed))
        @admin.admin = true
        @admin.client_authentication["testappid"] = "testestokenadmin"
        @admin.save
        puts @admin.errors.full_messages.to_s
        puts "the admin auth token isi::"
        puts @admin.authentication_token
        puts "----------------------------------------------"
        @admin_headers = { "CONTENT_TYPE" => "application/json" , "ACCEPT" => "application/json", "X-User-Token" => @admin.authentication_token, "X-User-Es" => @admin.client_authentication["testappid"], "X-User-Aid" => "testappid"}

        ## create a product.
		@product = Shopping::Product.new
		@product.name = "Cobas e411"
		@product.price = 500.00
		@product.signed_in_resource = @admin
		@product.resource_id = @admin.id.to_s
		@product.resource_class = @admin.class.name.to_s
		sp = @product.save
		puts "product successfully saved: #{sp.to_s}"

		## create another product
		@product = Shopping::Product.new
		@product.name = "Roche 423"
		@product.price = 500.00
		@product.signed_in_resource = @admin
		@product.resource_id = @admin.id.to_s
		@product.resource_class = @admin.class.name.to_s
		sp = @product.save
		puts "product successfully saved: #{sp.to_s}"

		## create a cart item based on above product
		@cart_item = Shopping::CartItem.new
		@cart_item.product_id = @product.id.to_s
		@cart_item.resource_class = @u.class.name.to_s
		@cart_item.resource_id = @u.id.to_s
		@cart_item.signed_in_resource = @u
		su = @cart_item.save
		puts "cart item saved: #{su.to_s}"


		## create one more user who shouldnt be able to see this cart item.
		@u2 = User.new(attributes_for(:user_confirmed))
		@u2.versioned_create
        @u2.client_authentication["testappid"] = "testestoken"
        @u2.save
        @u2_headers = { "CONTENT_TYPE" => "application/json" , "ACCEPT" => "application/json", "X-User-Token" => @u2.authentication_token, "X-User-Es" => @u2.client_authentication["testappid"], "X-User-Aid" => "testappid"}


        ## refresh all indices
        puts "refreshing user index"
        puts User.es.index.refresh
        puts "refreshing product index"
        puts Shopping::Product.es.index.refresh
        puts "refrehsing cart item index"
        puts Shopping::CartItem.es.index.refresh



	end


	context " -- signed in user -- " do 

		context " -- public resource -- " do 
			
			it " -- allows user to search -- ",:purr => true do 
				get authenticated_user_search_index_path({api_key: @ap_key, :current_app_id => "testappid", query: {query_string: "Coba", size:10}}),nil,@headers
				
				puts response.body.to_s
				results = JSON.parse(response.body)
				expect(response.code).not_to eq("401")
				expect(results.size).to eq(1)
			end

			it " -- allows admin to search -- ", :aurr => true do 
				get authenticated_user_search_index_path({api_key: @ap_key, :current_app_id => "testappid", query: {query_string: "Coba", size:10}}),nil,@admin_headers
				
				## so its not authenticating with this.

				expect(response.code).not_to eq("401")

				results = JSON.parse(response.body)
				puts JSON.pretty_generate(results)
				expect(results.size).to eq(1)
			
			end
		end

		context " -- private resource -- " do 
			
			

			it " -- allows user to search if he owns resource -- ", :pr_user => true do 

				get authenticated_user_search_index_path({api_key: @ap_key, :current_app_id => "testappid", query: {query_string: "Roc", size:10}}),nil,@headers

				results = JSON.parse(response.body)
				expect(response.code).not_to eq("401")
				expect(results.size).to eq(2)

			end

			it " -- allows user to find itself -- ", :search_self => true do 

				get authenticated_user_search_index_path({api_key: @ap_key, :current_app_id => "testappid", query: {query_string: @u.email[0..4]}}),nil,@headers
				results = JSON.parse(response.body)
				expect(response.code).not_to eq("401")
				expect(results.size).to eq(1)
			end


			
			it " -- allows admin to search -- " do 

				get authenticated_user_search_index_path({api_key: @ap_key, :current_app_id => "testappid", query: {query_string: "Roch", size:10}}),nil,@admin_headers

				results = JSON.parse(response.body)
				expect(response.code).not_to eq("401")
				expect(results.size).to eq(2)

			end

			it " -- doesnt allow user to search if he doesnt own the resource -- ", :pr_na do 

				get authenticated_user_search_index_path({api_key: @ap_key, :current_app_id => "testappid", query: {query_string: "Roc", size:10}}),nil,@u2_headers

				results = JSON.parse(response.body)
				#puts "this is the response body"
				#puts results.to_s
				expect(response.code).to eq("401")
				expect(results.size).to eq(1)

			end

		end

	end

	context " -- no signed in user -- " do 
		it " -- returns not authenticated -- " do 
			get authenticated_user_search_index_path({api_key: @ap_key, :current_app_id => "testappid", query: {query_string: "Roc", size:10}}),nil,{ "CONTENT_TYPE" => "application/json" , "ACCEPT" => "application/json"}
			
			expect(response.code).to eq("401")
		end
	end



end