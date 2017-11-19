require "rails_helper"

RSpec.describe "payment request spec",:payment => true, :shopping => true, :type => :request do 

	before(:all) do 
        ActionController::Base.allow_forgery_protection = false
        User.delete_all
        Auth::Client.delete_all
        @u = User.new(attributes_for(:user_confirmed))
        @u.save

        @c = Auth::Client.new(:resource_id => @u.id, :api_key => "test", :app_ids => ["test_app_id"])
        @c.redirect_urls = ["http://www.google.com"]
        @c.versioned_create
        @u.client_authentication["test_app_id"] = "test_es_token"
        @u.save
        @ap_key = @c.api_key
        @headers = { "CONTENT_TYPE" => "application/json" , "ACCEPT" => "application/json", "X-User-Token" => @u.authentication_token, "X-User-Es" => @u.client_authentication["test_app_id"], "X-User-Aid" => "test_app_id"}
        
        
    end


    context " -- cash, card, cheque payment -- " do 

        before(:example) do 
            @created_cart_item_ids = []
            @cart = Shopping::Cart.new
            @cart.save

            5.times do 
                cart_item = Shopping::CartItem.new(attributes_for(:cart_item))
                cart_item.resource_id = @u.id.to_s
                cart_item.resource_class = @u.class.name
                cart_item.parent_id = @cart.id
                cart_item.price = 10.00
                cart_item.save
                @created_cart_item_ids << cart_item.id.to_s
            end
           
        end

        after(:example) do 
            Shopping::CartItem.delete_all
            Shopping::Cart.delete_all
            Shopping::Payment.delete_all
        end


        it " -- creates a payment to the cart-- " do 
            
            post shopping_payments_path, {cart_id: @cart.id.to_s,payment_type: "cash", amount: 10, :api_key => @ap_key, :current_app_id => "test_app_id"}.to_json, @headers
                    
            expect(Shopping::Payment.count).to eq(1)
        
        end

        it " -- sets all cart items as accepted, if payment amount is sufficient for all the cart items. " do 
            

            post shopping_payments_path, {cart_id: @cart.id.to_s,payment_type: "cash", amount: 50.00, :api_key => @ap_key, :current_app_id => "test_app_id"}.to_json, @headers
                    
            expect(Shopping::Payment.count).to eq(1)
            
            @created_cart_item_ids.each do |id|
                cart_item = Shopping::CartItem.find(id)
                expect(cart_item.accepted).to be_truthy
            end


        end

        it " -- can update the payment status -- " do 

            k = Shopping::Payment.new
            k.cart_id = @cart.id.to_s
            k.payment_type = "cash"
            k.amount = 50.00
            k.save

            ## should be able to update this payment as 

        end

    end


    context " -- gateway payment -- " do 

    end


   


end