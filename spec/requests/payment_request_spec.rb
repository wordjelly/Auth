require "rails_helper"

RSpec.describe "payment request spec",:payment => true, :type => :request do 

	before(:all) do 
        ActionController::Base.allow_forgery_protection = false
        User.delete_all
        Auth::Client.delete_all
        Shopping::CartItem.delete_all
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
                cart_item.parent_id = @cart.id
                
                cart_item.save
                @created_cart_item_ids << cart_item.id.to_s
            end

        end

        after(:example) do 
            Shopping::CartItem.delete_all
            Shopping::Cart.delete_all
        end

        it " -- creates a payment -- " do 

        end


    end


    context " -- gateway payment -- " do 

    end


   


end