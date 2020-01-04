require "rails_helper"

RSpec.describe "bar_code request spec",:bar_code => true,:shopping => true, :type => :request do 

	before(:all) do 
        ActionController::Base.allow_forgery_protection = false
        User.delete_all
        Auth::Client.delete_all
        Shopping::CartItem.delete_all
        Shopping::Product.delete_all
        Auth::Shopping::BarCode.delete_all
        
        ## THIS PRODUCT IS USED IN THE CART_ITEM FACTORY, TO PROVIDE AND ID.
        
        #@product = Shopping::Product.new(:name => "test product", :price => 400.00)
       
        #@product.save

        @u = User.new(attributes_for(:user_confirmed))
        @u.save

        @c = Auth::Client.new(:resource_id => @u.id, :api_key => "test", :app_ids => ["testappid"])
        @c.redirect_urls = ["http://www.google.com"]
        @c.versioned_create
        @u.client_authentication["testappid"] = "testestoken"
        @u.save
        @ap_key = @c.api_key
        @headers = { "CONTENT_TYPE" => "application/json" , "ACCEPT" => "application/json", "X-User-Token" => @u.authentication_token, "X-User-Es" => @u.client_authentication["testappid"], "X-User-Aid" => "testappid"}
        


        ### CREATE ONE ADMIN USER

        ### It will use the same client as the user.
        @admin = User.new(attributes_for(:admin_confirmed))
        @admin.admin = true
        
        @admin.client_authentication["testappid"] = "testestoken2"
        @admin.save
        
        @admin_headers = { "CONTENT_TYPE" => "application/json" , "ACCEPT" => "application/json", "X-User-Token" => @admin.authentication_token, "X-User-Es" => @admin.client_authentication["testappid"], "X-User-Aid" => "testappid"}
        
    end



    context " -- json requests -- " do 

    	before(:each) do 
    		Shopping::CartItem.delete_all
	        Shopping::Product.delete_all
	        Auth::Shopping::BarCode.delete_all
    	end


    	it " -- assings a barcode to a product -- ", :assigns_bar_code => true do 

    		product = Auth.configuration.product_class.constantize.new
    		product.resource_id = @admin.id.to_s
    		product.resource_class = @admin.class.name
    		product.price = 10
    		product.name = "test product"
    		product.bar_code_tag = "hello world"
    		product.signed_in_resource = @admin

    		post shopping_products_path,{product: product.attributes.merge({:bar_code_tag => product.bar_code_tag}) , :api_key => @ap_key, :current_app_id => "testappid"}.to_json, @admin_headers


    		expect(response.code).to eq("201")

    		#puts (Auth::Shopping::BarCode.all.size)

    		#product = Shopping::Product.find(product.id)
    		
    		bar_code = Auth::Shopping::BarCode.where(:bar_code_tag => "hello world")
    		
    		expect(bar_code.first).not_to be_nil

    	end


    	it " -- removes barcode from product -- ", :remove_bar_code => true do 

    		product = Auth.configuration.product_class.constantize.new
    		product.resource_id = @admin.id.to_s
    		product.resource_class = @admin.class.name
    		product.price = 10
    		product.name = "test product"
    		product.bar_code_tag = "hello world"
    		product.signed_in_resource = @admin
    		expect(product.save).to be_truthy

    		product_to_update = {:product => {:remove_bar_code => "1"}, api_key: @ap_key, :current_app_id => "testappid"}

    		put shopping_product_path(:id => product.id.to_s),product_to_update.to_json,@admin_headers

    		expect(response.code).to eq("204")

    		bar_code = Auth::Shopping::BarCode.where(:assigned_to_object_id => product.id.to_s)
    		expect(bar_code.first).to be_nil

    	end

        it " -- remove barcode from product returns true, if that barcode was already removed from that product -- ", :remove_bar_code_twice => true do 

            product = Auth.configuration.product_class.constantize.new
            product.resource_id = @admin.id.to_s
            product.resource_class = @admin.class.name
            product.price = 10
            product.name = "test product"
            product.bar_code_tag = "hello world"
            product.signed_in_resource = @admin
            expect(product.save).to be_truthy

            product_to_update = {:product => {:remove_bar_code => "1"}, api_key: @ap_key, :current_app_id => "testappid"}

            put shopping_product_path(:id => product.id.to_s),product_to_update.to_json,@admin_headers

            expect(response.code).to eq("204")

            bar_code = Auth::Shopping::BarCode.where(:assigned_to_object_id => product.id.to_s)
            expect(bar_code.first).to be_nil

            expect(Auth::Shopping::BarCode.clear_object(product.id.to_s)).to be_truthy

        end


    	it " -- will not assing the same barcode to another object , saves the object, but will still return a 422, but will not assign the barcode. -- ", :bar_code_unique => true do 

			product = Auth.configuration.product_class.constantize.new
    		product.resource_id = @admin.id.to_s
    		product.resource_class = @admin.class.name
    		product.price = 10
    		product.name = "test product"
    		product.bar_code_tag = "hello world"
    		product.signed_in_resource = @admin
    		expect(product.save).to be_truthy

    		product_two = Shopping::Product.new
    		product_two.resource_id = @admin.id.to_s
    		product_two.resource_class = @admin.class.name
    		product_two.price = 10
    		product_two.name = "test product"
    		product_two.bar_code_tag = "hello world"
    		product_two.signed_in_resource = @admin
    		#expect(product_two.save).to be_truthy
    		#expect(product_two.errors).not_to be_empty

    		post shopping_products_path,{product: product_two.attributes.merge({:bar_code_tag => product_two.bar_code_tag}) , :api_key => @ap_key, :current_app_id => "testappid"}.to_json, @admin_headers
    		expect(response.code).to eq("422")
    		## product still gets saved.

    		bar_code = Auth::Shopping::BarCode.all
    		expect(bar_code.size).to eq(1)
    		expect(bar_code.first.assigned_to_object_id).to eq(product.id.to_s)

    	end

        it " - reassings the barcode to another object, if it has been removed from one object -- " do 

            

        end

    end

end