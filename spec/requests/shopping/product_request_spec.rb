require "rails_helper"

RSpec.describe "cart item request spec",:product_embedded => true,:shopping => true, :type => :request do 

	before(:all) do 
        ActionController::Base.allow_forgery_protection = false
        User.delete_all
        Auth::Client.delete_all
        Shopping::CartItem.delete_all
        Shopping::Product.delete_all
        
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

    	before(:example) do 
    		#Shopping::CartItem.delete_all
            #Shopping::Product.delete_all
    	    Auth.configuration.product_class.constantize.delete_all
            Auth.configuration.cart_item_class.constantize.delete_all
        end	

        it " -- creates a product with three instructions and each instruction with three bullets -- " do 

            product = Auth.configuration.product_class.constantize.new
            product.name = "first product"
            product.price = 200

            instructions = []
            1.times do |n|
                instruction = Auth::Work::Instruction.new
                instruction.title = "Before Test"
                1.times do |b|
                    bullet = Auth::Work::Bullet.new
                    bullet.text = "this is the #{b} bullet"
                    instruction.bullets << bullet
                end
                instructions << instruction
            end 

            product.embedded_document_path = "instructions"
            product.embedded_document = instructions

            post shopping_products_path,{product: product,:api_key => @ap_key, :current_app_id => "testappid"}.to_json, @admin_headers

            product_created = assigns(:auth_shopping_product)
            puts "total products------------"
            puts Auth.configuration.product_class.constantize.all.size
            expect(product_created.instructions).not_to be_empty

        end

        it " -- updates an embedded document using a path -- " do 

            product = Auth.configuration.product_class.constantize.new
            product.name = "first product"
            product.price = 200
            product.resource_id = @admin.id.to_s
            product.resource_class = @admin.class.name.to_s
            product.signed_in_resource = @admin

            instructions = []
            1.times do |n|
                instruction = Auth::Work::Instruction.new
                instruction.title = "Before Test"
                1.times do |b|
                    bullet = Auth::Work::Bullet.new
                    bullet.text = "this is the #{b} bullet"
                    instruction.bullets << bullet
                end
                instructions << instruction
            end 

            product.instructions = instructions
            product.valid?
            puts product.errors.full_messages
            expect(product.save).to be_truthy


            ## now we update the text of the first bullet
            embedded_document = "this is the new text"
            embedded_document_path = "instructions.0.bullets.0.text"

            a = {:product => {:embedded_document => embedded_document, :embedded_document_path => embedded_document_path}}

            put shopping_product_path({:id => product.id.to_s,:api_key => @ap_key, :current_app_id => "testappid"}), a.to_json,@admin_headers
            
            #puts response.body.to_s
            #puts response.code.to_s

            updated_product = assigns(:auth_shopping_product)
            expect(response.code).to eq("204")
            expect(updated_product.instructions[0].bullets[0].text).to eq("this is the new text")
        end


        it " -- adds images/ videos to the bullets -- " do 



        end


        it " -- deletes a bullet -- " do 

            ## so we want to set a bullet to newil.
            product = Auth.configuration.product_class.constantize.new
            product.name = "first product"
            product.price = 200
            product.resource_id = @admin.id.to_s
            product.resource_class = @admin.class.name.to_s
            product.signed_in_resource = @admin

            instructions = []
            1.times do |n|
                instruction = Auth::Work::Instruction.new
                instruction.title = "Before Test"
                1.times do |b|
                    bullet = Auth::Work::Bullet.new
                    bullet.text = "this is the #{b} bullet"
                    instruction.bullets << bullet
                end
                instructions << instruction
            end 

            product.instructions = instructions
            product.valid?
            puts product.errors.full_messages
            expect(product.save).to be_truthy


            ## now we update the text of the first bullet
            embedded_document = nil
            embedded_document_path = "instructions.0.bullets.0"

            a = {:product => {:embedded_document => embedded_document, :embedded_document_path => embedded_document_path}}

            put shopping_product_path({:id => product.id.to_s,:api_key => @ap_key, :current_app_id => "testappid"}), a.to_json,@admin_headers
            
            #puts response.body.to_s
            #puts response.code.to_s

            updated_product = assigns(:auth_shopping_product)
            expect(response.code).to eq("204")


        end


        it " -- deletes an instruction -- " do 


        end


        it " -- show product returns summary, and individual instructions with bullets -- " do 


        end


        it "-- product parameter can be created and updated -- " do 


        end

        it " -- parameters can be given options -- " do 

        end

        it " -- parameter options can be selected -- " do 


        end

        it " -- generates instructions based on variables and actors -- " do 

        end
        
    end

end