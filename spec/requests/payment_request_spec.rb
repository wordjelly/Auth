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
            Shopping::CartItem.delete_all
            Shopping::Cart.delete_all
            Shopping::Payment.delete_all
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

            

        end

        it " -- if payment status is set as false, cart item statuses are also updated -- " do 
            

        end

    end


    context " -- gateway payment -- " do 

    end

    context " -- payment cannot be destroyed -- " do 


    end
   


end


=begin

-so basically it buys down to this->

-1. before_remove - check if status is accepted, if yes, then 
it cannot be removed, provide a hook to override this method as per the needs.

- here only there is fork - that if removal fails, then provide:
on_cannot_remove_item_hook

-2. after_remove - create a payment refund to the customer for the amount equalling the removed amount.

-3. provide a method to cancel all the tests in the cart, this is done by calling destroy cart - if call destroy cart, then where will we show the refund?
- refund should also be shown in the cart.

so you cannot destroy the cart if payments have already been made to it.
you can only remove items from the cart, i.e all the items.
and there you can show the refunds.

so before destroy cart - check if payments have been made, and if yes, then don't destroy the cart.


-4. basically we have to make a payment to the user.
    thats the essence.
    so the payment should have a pay_to
    it will also have a type, this will be the same as the last payment made by the user.
    it will have to be done by the business seperately.
    notification behaviour has to be defined, for eg: 
    
    refund can be by cheque only at this stage. 
    the refund is successfull if the cheque is ready.

    After refund success, a callback has to notify the payee, that his cheque can be picked up,

    at this stage the acknowledgement proof can be picked up, saying that his payment was successfully received.
    


=end





