require "rails_helper"

RSpec.describe "cart item request spec",:cart_item => true, :type => :request do 

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

    context " -- json requests -- " do 
    ##HERE WE ASSUME THAT THE ABOVE USER IS ONLY INTERACTING WITH THE CART_ITEM_CONTROLLER.

		context " -- security " do 

			context " -- needs api key and app_id " do 

				it " -- fails on create without " do 
					cart_item = attributes_for(:cart_item)
					post shopping_cart_items_path,{cart_item: cart_item}.to_json, @headers
	            	@cart_item_created = assigns(:cart_item)
	            	expect(response.body).to be_empty
	            	expect(response.code).to eq("401")
				end

			end

			context " -- needs auth token and es " do 

				it " -- fails to create " do 

					cart_item = attributes_for(:cart_item)
					@headers = { "CONTENT_TYPE" => "application/json" , "ACCEPT" => "application/json"}
					post shopping_cart_items_path,{cart_item: cart_item,:api_key => @ap_key, :current_app_id => "test_app_id"}.to_json,@headers
	            	expect(response.code).to eq("401")
				end

			end

		end

		context " -- create " do 

			it " -- creates cart item with all permitted params,and assigns user id. " do 
				cart_item = attributes_for(:cart_item)
				post shopping_cart_items_path,{cart_item: cart_item,:api_key => @ap_key, :current_app_id => "test_app_id"}.to_json, @headers
	            @cart_item_created = assigns(:cart_item)
	            cart_item_hash = JSON.parse(response.body)
	            cart_item.keys.each do |ck|
	            	expect(cart_item_hash[ck.to_s]).to eq(cart_item[ck])
	            end
	            expect(cart_item_hash["resource_id"]).to eq(@u.id.to_s)
			end

		end

		context "-- update" do 

			it " -- only updates discount and quantity " do 
				
				cart_item = Shopping::CartItem.new(attributes_for(:cart_item))
				cart_item.resource_id = @u.id.to_s
				cart_item.save
				
	            a = {:cart_item => {:discount => 42, :quantity => 10, :product_id => BSON::ObjectId.new.to_s, :price => 400}, api_key: @ap_key, :current_app_id => "test_app_id"}
	            
	            ##have to post to the id url.
	            put shopping_cart_item_path({:id => cart_item.id.to_s}), a.to_json,@headers
				updated_cart_item = assigns(:cart_item)
				expect(response.code).to eq("204")
				##get the updated 
				#expect(updated_cart_item.discount).to eq(42)
				expect(updated_cart_item.quantity).to eq(10)
				expect(updated_cart_item.price).to eq(cart_item.price)
				expect(updated_cart_item.product_id).to eq(cart_item.product_id)
			end

			it " -- only updates if the user owns the cart item " do 
				##we create another user and pass his auth token, es and app id, and then it should not perform the update, but throw a not found.
				@u1 = User.new(attributes_for(:user_confirmed))
	       	 	@u1.save
	       	 	@u1.client_authentication["test_app_id"] = "test_es_token"
	        	@u1.save
	        	##so basically we are going to use the client from @u only here as well.
	        	cart_item = Shopping::CartItem.new(attributes_for(:cart_item))
				cart_item.resource_id = @u.id.to_s
				cart_item.save
				
	            a = {:cart_item => {:discount => 42, :quantity => 10, :product_id => BSON::ObjectId.new.to_s, :price => 400}, api_key: @ap_key, :current_app_id => "test_app_id"}
	            @headers = { "CONTENT_TYPE" => "application/json" , "ACCEPT" => "application/json", "X-User-Token" => @u1.authentication_token, "X-User-Es" => @u1.client_authentication["test_app_id"], "X-User-Aid" => "test_app_id"}
	            ##have to post to the id url.
	            put shopping_cart_item_path({:id => cart_item.id.to_s}), a.to_json,@headers
	            resp = JSON.parse(response.body)
	            expect(resp.keys).to include("errors")
			end

		end

		context " -- destroy -- " do 

			it  " -- returns 204 " do 
				cart_item = Shopping::CartItem.new(attributes_for(:cart_item))
				cart_item.resource_id = @u.id.to_s
				cart_item.save
				@headers = { "CONTENT_TYPE" => "application/json" , "ACCEPT" => "application/json", "X-User-Token" => @u.authentication_token, "X-User-Es" => @u.client_authentication["test_app_id"], "X-User-Aid" => "test_app_id"}
				delete shopping_cart_item_path({:id => cart_item.id.to_s}),{api_key: @ap_key, :current_app_id => "test_app_id"}.to_json,@headers
				expect(response.code).to eq("204")
				expect(response.body).to be_empty
			end
		end

		context " -- index " do 

			it " -- returns the cart items belonging to this user " do 
				created_cart_item_ids = []
				5.times do 
					cart_item = Shopping::CartItem.new(attributes_for(:cart_item))
					cart_item.resource_id = @u.id.to_s
					cart_item.save
					created_cart_item_ids << cart_item.id.to_s
				end
				@headers = { "CONTENT_TYPE" => "application/json" , "ACCEPT" => "application/json", "X-User-Token" => @u.authentication_token, "X-User-Es" => @u.client_authentication["test_app_id"], "X-User-Aid" => "test_app_id"}
				get shopping_cart_items_path({api_key: @ap_key, :current_app_id => "test_app_id"}),nil,@headers
				returned_objects = JSON.parse(response.body)
				returned_objects.each { |r|
					citem = Shopping::CartItem.new(r)
					if created_cart_item_ids.include? citem.id.to_s
						created_cart_item_ids.delete(citem.id.to_s)
					end
				}
				expect(created_cart_item_ids).to be_empty
			end	

			it "returns empty response if no cart items exist for this user" do 
				Shopping::CartItem.delete_all
				@headers = { "CONTENT_TYPE" => "application/json" , "ACCEPT" => "application/json", "X-User-Token" => @u.authentication_token, "X-User-Es" => @u.client_authentication["test_app_id"], "X-User-Aid" => "test_app_id"}
				get shopping_cart_items_path({api_key: @ap_key, :current_app_id => "test_app_id"}),nil,@headers
				returned_objects = JSON.parse(response.body)
				expect(returned_objects).to be_empty
			end

		end

		context  " -- show ", :test_now => true do 

			it " -- returns nil if resource doesnt own the cart_item " do 
				##we create another user and pass his auth token, es and app id, and then it should not perform the update, but throw a not found.
				@u2 = User.new(attributes_for(:user_confirmed))
	       	 	@u2.save
	       	 	@u2.client_authentication["test_app_id"] = "test_es_token"
	        	@u2.save
	        	##so basically we are going to use the client from @u only here as well.
	        	cart_item = Shopping::CartItem.new(attributes_for(:cart_item))
				cart_item.resource_id = @u.id.to_s
				cart_item.save
				
	            @headers = { "CONTENT_TYPE" => "application/json" , "ACCEPT" => "application/json", "X-User-Token" => @u2.authentication_token, "X-User-Es" => @u2.client_authentication["test_app_id"], "X-User-Aid" => "test_app_id"}
	            get shopping_cart_item_path({:id => cart_item.id.to_s,api_key: @ap_key, :current_app_id => "test_app_id"}),nil,@headers

	            expect(response.body).to eq("{}")

			end

		end

	end

end
