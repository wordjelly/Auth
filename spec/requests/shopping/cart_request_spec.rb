require "rails_helper"

RSpec.describe "cart request spec",:cart => true,:shopping => true, :type => :request do 

	before(:all) do 
        ActionController::Base.allow_forgery_protection = false
        User.delete_all
        Auth::Client.delete_all
        Shopping::CartItem.delete_all
        Shopping::Product.delete_all
        @u = User.new(attributes_for(:user_confirmed))
        @u.save
        @u.client_authentication["testappid"] = "testestoken"
        @u.save

        ## THIS PRODUCT IS USED IN THE CART_ITEM FACTORY, TO PROVIDE AND ID.
        @product = Shopping::Product.new(:name => "test product", :price => 400.00)
       
        @product.save


        @c = Auth::Client.new(:resource_id => @u.id, :api_key => "test", :app_ids => ["testappid"])
        @c.redirect_urls = ["http://www.google.com"]
        @c.versioned_create
        
        @ap_key = @c.api_key
       
        
        ### CREATE ONE ADMIN USER

        ### It will use the same client as the user.
        @admin = User.new(attributes_for(:admin_confirmed))
        @admin.admin = true
        @admin.client_authentication["testappid"] = "testestoken2"
        @admin.save
        @admin_headers = { "CONTENT_TYPE" => "application/json" , "ACCEPT" => "application/json", "X-User-Token" => @admin.authentication_token, "X-User-Es" => @admin.client_authentication["testappid"], "X-User-Aid" => "testappid"}
        
    end


    context " -- web show request " do 

    	before(:example) do 
			@created_cart_item_ids = []
			@cart = Shopping::Cart.new
			@cart.resource_class = @u.class.name
			@cart.resource_id = @u.id.to_s
			@cart.save

			5.times do 
				cart_item = Shopping::CartItem.new(attributes_for(:cart_item))
                cart_item.resource_id = @u.id.to_s
                cart_item.resource_class = @u.class.name
                cart_item.parent_id = @cart.id
                cart_item.price = 10.00
                cart_item.signed_in_resource = @admin
                k = cart_item.save
                puts cart_item.product_id.to_s
                puts "result of save is: #{k.to_s}"
                @created_cart_item_ids << cart_item.id.to_s
			end

		end

		after(:example) do 
			Shopping::CartItem.delete_all
		end

    	it "--- shows the items in the cart ",:sc => true do
    		sign_in(@u)
    		get shopping_cart_path(@cart)
			cart_items = Hash[assigns(:auth_shopping_cart_items).map { |c| c = [c.id.to_s,c]  }]
			@created_cart_item_ids.each do |c|
				expect(cart_items[c]).not_to be_nil
			end

    	end

    end


	context " -- json requests  -- " do 

		## reload user because in the web app requests, we do sign_in user, and that causes a save and causes the auth_token to change, so we need to recreate user here.
		before(:all) do 
			User.delete_all
			@u = User.new(attributes_for(:user_confirmed))
	        @u.save
	        @u.client_authentication["testappid"] = "testestoken"
	        @u.save
	        @headers = { "CONTENT_TYPE" => "application/json" , "ACCEPT" => "application/json", "X-User-Token" => @u.authentication_token, "X-User-Es" => @u.client_authentication["testappid"], "X-User-Aid" => "testappid"}
        
		end

		context " -- show -- " do 

			before(:example) do 
				Shopping::CartItem.delete_all
				Shopping::Cart.delete_all
				@created_cart_item_ids = []
				@cart = Shopping::Cart.new
				@cart.resource_class = @u.class.to_s
				@cart.resource_id = @u.id.to_s
				@cart.save

				5.times do 
					cart_item = Shopping::CartItem.new(attributes_for(:cart_item))
					cart_item.resource_class = @u.class.name
					cart_item.resource_id = @u.id.to_s
	                cart_item.signed_in_resource = @admin
	                cart_item.parent_id = @cart.id.to_s
	                cart_item.save

	                @created_cart_item_ids << cart_item.id.to_s
				end
			end

			after(:example) do 
				Shopping::CartItem.delete_all
				Shopping::Cart.delete_all
			end

			it  " -- shows the cart -- ", :show_cart => true do 

				get shopping_cart_path(:id => @cart.id.to_s), {:api_key => @ap_key, :current_app_id => "testappid"}, @headers
				cart_response = JSON.parse(response.body)
				puts "-----------------------------------------"
				puts "this is the response code"
				puts response.code.to_s
				puts "response body"
				puts "this is the response body."
				puts response.body.to_s
				expect(cart_response["cart_minimum_payable_amount"]).to eq("10.0")
				expect(response.code).to eq("200")
			end

		end

		context " -- create -- " do 
			before(:example) do 
				@created_cart_item_ids = []
				@cart = Shopping::Cart.new
				@cart.save

				5.times do 
					cart_item = Shopping::CartItem.new(attributes_for(:cart_item))
					cart_item.resource_class = @u.class.name
					cart_item.resource_id = @u.id.to_s
	                cart_item.signed_in_resource = @admin
	                cart_item.save

	                @created_cart_item_ids << cart_item.id.to_s
				end
			end

			after(:example) do 
				Shopping::CartItem.delete_all
				Shopping::Cart.delete_all
			end

			it " -- creates a new cart, and simultaneously returns no cart_items on cart_item#index action -- ", :qr => true do 
				

				post shopping_carts_path, {cart: {add_cart_item_ids: @created_cart_item_ids},:api_key => @ap_key, :current_app_id => "testappid"}.to_json, @headers
				

				
				jresp = JSON.parse(response.body)
				ct = Shopping::Cart.new(jresp)
				expect(ct.errors).to be_empty
				cart_items = ct.find_cart_items
				expect(cart_items.size).to eq(@created_cart_item_ids.size)

				## now we need to find cart items which would be returned in the index action of the cart_item_controller.
				## these should not be seen.
				@cart_items = Shopping::CartItem.find_cart_items({:resource => @u})
				
				expect(@cart_items).to be_empty

			end

			it " -- id is provided, without add_cart_items paramenter, it returns an error. -- ", issue: true do 

				post shopping_carts_path, {cart: {},:api_key => @ap_key, :current_app_id => "testappid", :id => BSON::ObjectId.new.to_s}.to_json, @headers

				jresp = JSON.parse(response.body)
				##it will give an error because we cannot find this id.
				expect(jresp["errors"]).not_to be_empty
			end


			it " -- some of the cart items ids provided don't exist, only updates the existing cart items with this cart's id. -- " do 

				@created_cart_item_ids.pop
				post shopping_carts_path, {cart: {add_cart_item_ids: @created_cart_item_ids},:api_key => @ap_key, :current_app_id => "testappid"}.to_json, @headers
				
				jresp = JSON.parse(response.body)
				ct = Shopping::Cart.new(jresp)
				expect(ct.errors).to be_empty
				cart_items = ct.find_cart_items
				expect(cart_items.size).to eq(4)

			end

		end


		context " -- update -- " do 
			before(:example) do 
				@created_cart_item_ids = []
				
				## create a cart with some cart items.
				@cart = Shopping::Cart.new
				@cart.resource_class = @u.class.name
				@cart.resource_id = @u.id.to_s
				@cart.save

				5.times do 
					cart_item = Shopping::CartItem.new(attributes_for(:cart_item))
	                cart_item.resource_id = @u.id.to_s
	                cart_item.resource_class = @u.class.name
	                cart_item.parent_id = @cart.id
	                cart_item.signed_in_resource = @admin
	                cart_item.price = 10.00
	                cart_item.save
	                @created_cart_item_ids << cart_item.id.to_s
				end

			end

			after(:example) do 
				Shopping::CartItem.delete_all
			end


			##scenario -> add a few new cart items, but also add name on transaction, and remove some of the older cart items

			it " -- adds name and notes to cart, and adds the new cart items, and removes the required cart items.", :cart_update => true do 

				##


				##this is the new cart item to be added
				cart_item = Shopping::CartItem.new(attributes_for(:cart_item))
				cart_item.resource_id = @u.id.to_s
				cart_item.resource_class = @u.class.name
				cart_item.signed_in_resource = @admin
				cart_item.save

				##the cart item to be removed
				id_to_remove = @created_cart_item_ids.last

				##notes to be added to all cart items.
				@notes = "aies blood test when she was not well"

				put shopping_cart_path({:id => @cart.id}), {cart: {add_cart_item_ids: [cart_item.id.to_s], remove_cart_item_ids: [id_to_remove],parent_notes: @notes},:api_key => @ap_key, :current_app_id => "testappid"}.to_json, @headers

				puts "response code:"
				puts response.code.to_s

				
				cart_items = Shopping::CartItem.where(:parent_id => @cart.id)
				##check that the cart item was successfully removed
				
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
		            cart_item.signed_in_resource = @admin
		            cart_item.parent_id = @cart.id.to_s
		            cart_item.save
	            	@created_cart_item_ids << cart_item.id.to_s
	            end	

	            ## make a few additional cart items , so that these should be visible initially in the cart_item#index call.

	            @additional_cart_item = Shopping::CartItem.new(attributes_for(:cart_item))
	            @additional_cart_item.resource_id = @u.id.to_s
	            @additional_cart_item.resource_class = @u.class.name.to_s
	            @additional_cart_item.signed_in_resource = @admin
	            @additional_cart_item.save

			end

			after(:example) do 
				Shopping::CartItem.delete_all
				Shopping::Cart.delete_all
				Shopping::Payment.delete_all
			end

			it " -- additional cart item is visible before adding to cart -- " do 

				cart_items = Shopping::CartItem.find_cart_items({:resource => @u})
				
				expect(cart_items.size).to eq(1)

			end

			it " -- additional cart item is not visible after adding to cart -- ", :invisible => true do 

				put shopping_cart_path({:id => @cart.id}), {cart: {add_cart_item_ids: [@additional_cart_item.id.to_s]},:api_key => @ap_key, :current_app_id => "testappid"}.to_json, @headers

				puts "response body"
				puts response.body.to_s

				cart_items = Shopping::CartItem.find_cart_items({:resource => @u})
				puts "first item"
				puts cart_items.first.to_s
				expect(cart_items).to be_empty

			end

			it " -- on removing from cart , it is once again visible -- " do 


				put shopping_cart_path({:id => @cart.id}), {cart: {remove_cart_item_ids: [@additional_cart_item.id.to_s]},:api_key => @ap_key, :current_app_id => "testappid"}.to_json, @headers


				cart_items = Shopping::CartItem.find_cart_items({:resource => @u})
				
				expect(cart_items.size).to eq(1)


			end


			it " -- doesn't remove item if accepted is true -- " do 

				## first add the item into the cart, after setting accepted to true.
				@additional_cart_item.parent_id = @cart.id.to_s
				@additional_cart_item.accepted = true
				@additional_cart_item.save

				

				put shopping_cart_path({:id => @cart.id}), {cart: {remove_cart_item_ids: [@additional_cart_item.id.to_s]},:api_key => @ap_key, :current_app_id => "testappid"}.to_json, @headers				

			
				cart_items = Shopping::CartItem.find_cart_items({:resource => @u})
				
				expect(cart_items.size).to eq(0)

			end

			


		end


		context " -- create and update show validation errors if some cart items cannot be added or removed -- " do 

			
			

		end


		context " -- destroy -- " do 

			before(:example) do 
				@created_cart_item_ids = []
				
				
				@cart = Shopping::Cart.new
				@cart.resource_id = @u.id.to_s
				@cart.resource_class = @u.class.name.to_s
				@cart.save

				5.times do 
					cart_item = Shopping::CartItem.new(attributes_for(:cart_item))
	                cart_item.resource_id = @u.id.to_s
	                cart_item.resource_class = @u.class.name
	                cart_item.parent_id = @cart.id
	                cart_item.price = 10.00
	                cart_item.signed_in_resource = @admin
	                cart_item.save
	                @created_cart_item_ids << cart_item.id.to_s
				end

			end

			after(:example) do 
				Shopping::CartItem.delete_all
			end



			it " -- doesnt allow the cart to be destroyed if cart items have already been accepted -- ", :delete_cart do 

				## if the cart has items that were accepted, then it cannot be destroyed.
				Shopping::CartItem.each_with_index {|c_item,key|
					if key % 2 == 0
						c_item.accepted = true
						c_item.signed_in_resource = @admin
						c_item.save
					end
				}

				delete shopping_cart_path({:id => @cart.id}),{:api_key => @ap_key, :current_app_id => "testappid"}.to_json, @headers

				shopping_cart_ids = Shopping::Cart.all.map{|c| c = c.id.to_s}

				expect(shopping_cart_ids.include? @cart.id.to_s).to be_truthy

			end

			it " -- doesnt allow the cart to be destroyed if any payments are even pending, successfull or failed on the cart -- ", :delete_cart => true do 

				## create and save a payment to the cart.
				payment = Shopping::Payment.new
	            payment.payment_type = "cash"
	            payment.amount = 50.00
	            payment.resource_id = @u.id.to_s
	            payment.resource_class = @u.class.name.to_s
	            payment.cart_id = @cart.id.to_s
	            payment.signed_in_resource = @admin
	            ps = payment.save
	            expect(ps).to be_truthy

	            delete shopping_cart_path({:id => @cart.id}),{:api_key => @ap_key, :current_app_id => "testappid"}.to_json, @headers

				shopping_cart_ids = Shopping::Cart.all.map{|c| c = c.id.to_s}

				expect(shopping_cart_ids.include? @cart.id.to_s).to be_truthy


			end


		end

		

	end		

	context " -- accepts additional parameters -- " do 
		
	end

end

