require "rails_helper"

RSpec.describe "cart request spec",:cart => true,:shopping => true, :type => :request do 

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


    context " -- web show request " do 

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
		end

    	it "--- shows the items in the cart " do
    		sign_in(@u)
    		get shopping_cart_path(@cart)
			cart_items = Hash[assigns(:cart_items).map { |c| c = [c.id.to_s,c]  }]
			@created_cart_item_ids.each do |c|
				expect(cart_items[c]).not_to be_nil
			end

    	end

    end


	context " -- json requests  -- " do 


		context " -- create -- " do 
			before(:example) do 
				@created_cart_item_ids = []
				@cart = Shopping::Cart.new
				@cart.save

				5.times do 
					cart_item = Shopping::CartItem.new(attributes_for(:cart_item))
	                cart_item.save
	                @created_cart_item_ids << cart_item.id.to_s
				end
			end

			after(:example) do 
				Shopping::CartItem.delete_all
			end

			it " -- creates a new cart, and simultaneously returns no cart_items on cart_item#index action -- ", :cd => true do 
				

				post shopping_carts_path, {cart: {add_cart_item_ids: @created_cart_item_ids},:api_key => @ap_key, :current_app_id => "test_app_id"}.to_json, @headers
					
				jresp = JSON.parse(response.body)
				ct = Shopping::Cart.new(jresp)
				expect(ct.errors).to be_empty
				cart_items = ct.find_cart_items(@u)
				expect(cart_items.size).to eq(@created_cart_item_ids.size)

				## now we need to find cart items which would be returned in the index action of the cart_item_controller.
				## these should not be seen.
				@cart_items = Shopping::CartItem.find_cart_items({:resource => @u})
				
				expect(@cart_items).to be_empty

			end

			it " -- id is provided, without add_cart_items paramenter, it returns an error. -- ", issue: true do 

				post shopping_carts_path, {cart: {},:api_key => @ap_key, :current_app_id => "test_app_id", :id => BSON::ObjectId.new.to_s}.to_json, @headers

				jresp = JSON.parse(response.body)
				##it will give an error because we cannot find this id.
				expect(jresp["errors"]).not_to be_empty
			end


			it " -- some of the cart items ids provided don't exist, only updates the existing cart items with this cart's id. -- ", issue: true do 

				@created_cart_item_ids.pop
				post shopping_carts_path, {cart: {add_cart_item_ids: @created_cart_item_ids},:api_key => @ap_key, :current_app_id => "test_app_id"}.to_json, @headers
				
				jresp = JSON.parse(response.body)
				ct = Shopping::Cart.new(jresp)
				expect(ct.errors).to be_empty
				cart_items = ct.find_cart_items(@u)
				expect(cart_items.size).to eq(4)

			end

		end


		context " -- update -- " do 
			before(:example) do 
				@created_cart_item_ids = []
				
				## create a cart with some cart items.
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
			end


			##scenario -> add a few new cart items, but also add name on transaction, and remove some of the older cart items

			it " -- adds name and notes to cart, and adds the new cart items, and removes the required cart items." do 

				##


				##this is the new cart item to be added
				cart_item = Shopping::CartItem.new(attributes_for(:cart_item))
				
				cart_item.save

				##the cart item to be removed
				id_to_remove = @created_cart_item_ids.last

				##notes to be added to all cart items.
				@notes = "aies blood test when she was not well"

				put shopping_cart_path({:id => @cart.id}), {cart: {add_cart_item_ids: [cart_item.id.to_s], remove_cart_item_ids: [id_to_remove],parent_notes: @notes},:api_key => @ap_key, :current_app_id => "test_app_id"}.to_json, @headers

				
				cart_items = Shopping::CartItem.where(:parent_id => @cart.id)
				##check that the cart item was successfully removed
				##check that the notes are present on each cart item.
				cart_items_map = Hash[cart_items.map{|c| c.id.to_s}.zip(cart_items)]
				
				##the item to be added should be there.
				expect(cart_items_map[cart_item.id.to_s]).not_to be_nil
				##the item to be removed should not be there
				expect(cart_items_map[id_to_remove]).to be_nil
				##the total length should be five.
				expect(cart_items_map.size).to eq(5)
			end

			
		end


		context " -- adding and removing cart items from the cart -- ", :add_remove => true do 

			before(:example) do 
			
				Shopping::CartItem.delete_all
				Shopping::Cart.delete_all

				## create a cart.
				@cart = Shopping::Cart.new
				@cart.resource_id = @u.id.to_s
				@cart.resource_class = @u.class.name.to_s
				@cart.save

				@created_cart_item_ids = []
				5.times do 
					cart_item = Shopping::CartItem.new(attributes_for(:cart_item))
		            cart_item.resource_id = @u.id.to_s
		            cart_item.resource_class = @u.class.name
		            cart_item.parent_id = @cart.id.to_s
		            cart_item.save
	            	@created_cart_item_ids << cart_item.id.to_s
	            end	

	            ## make a few additional cart items , so that these should be visible initially in the cart_item#index call.

	            @additional_cart_item = Shopping::CartItem.new(attributes_for(:cart_item))
	            @additional_cart_item.resource_id = @u.id.to_s
	            @additional_cart_item.resource_class = @u.class.name.to_s
	            @additional_cart_item.save

			end


			it " -- additional cart item is visible before adding to cart -- " do 

				cart_items = Shopping::CartItem.find_cart_items({:resource => @u})
				
				expect(cart_items.size).to eq(1)

			end

			it " -- additional cart item is not visible after adding to cart -- " do 

				put shopping_cart_path({:id => @cart.id}), {cart: {add_cart_item_ids: [@additional_cart_item.id.to_s]},:api_key => @ap_key, :current_app_id => "test_app_id"}.to_json, @headers

				cart_items = Shopping::CartItem.find_cart_items({:resource => @u})
				
				expect(cart_items).to be_empty

			end

			it " -- on removing from cart , it is once again visible -- " do 

				put shopping_cart_path({:id => @cart.id}), {cart: {remove_cart_item_ids: [@additional_cart_item.id.to_s]},:api_key => @ap_key, :current_app_id => "test_app_id"}.to_json, @headers

				cart_items = Shopping::CartItem.find_cart_items({:resource => @u})
				
				expect(cart_items.size).to eq(1)


			end


		end

		context " -- destroy -- " do 

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
			end


			it " -- destroys the cart, and removes the parent id from all cart items before doing so. " do 

				delete shopping_cart_path({:id => @cart.id}),{:api_key => @ap_key, :current_app_id => "test_app_id"}.to_json, @headers

				cart_items = Shopping::CartItem.where(:parent_id => @cart.id.to_s)

				expect(cart_items.size).to eq(0)

			end

		end

		

	end		

end

