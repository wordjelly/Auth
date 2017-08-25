require "rails_helper"

RSpec.describe "cart request spec",:transaction => true, :type => :request do 

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

	context " -- json requests  -- " do 


		context " -- create -- " do 
			before(:example) do 
				@created_cart_item_ids = []
				5.times do 
					cart_item = Shopping::CartItem.new(attributes_for(:cart_item))
					cart_item.resource_id = @u.id.to_s
					cart_item.save
					@created_cart_item_ids << cart_item.id.to_s
				end
			end

			after(:example) do 
				Shopping::CartItem.delete_all
			end

			it " -- creates a new transaction , returns cart_items array -- " do 
				

				post shopping_transactions_path, {transaction: {add_cart_item_ids: @created_cart_item_ids},:api_key => @ap_key, :current_app_id => "test_app_id"}.to_json, @headers
					
				jresp = JSON.parse(response.body)
				jresp.map { |c| c = Shopping::CartItem.new(c) }
				expect(jresp.size).to eq(@created_cart_item_ids.size)

			end

			it " -- id is provided, without add_cart_items paramenter, it just returns an empty array -- " do 

				post shopping_transactions_path, {transaction: {},:api_key => @ap_key, :current_app_id => "test_app_id", :id => BSON::ObjectId.new.to_s}.to_json, @headers

				jresp = JSON.parse(response.body)
				expect(jresp).to match_array([])
			end


			it " -- some of the cart items ids provided don't exist, it returns the existing ones only -- " do 

				@created_cart_item_ids.pop
				post shopping_transactions_path, {transaction: {add_cart_item_ids: @created_cart_item_ids},:api_key => @ap_key, :current_app_id => "test_app_id"}.to_json, @headers
					
				jresp = JSON.parse(response.body)
				jresp.map { |c| c = Shopping::CartItem.new(c) }
				expect(jresp.size).to eq(@created_cart_item_ids.size)		
				expect(jresp.size).to eq(4)		

			end

		end

		context " -- update -- ", transaction_update: true do 
			before(:example) do 
				@created_cart_item_ids = []
				##create a transaction on each of them.
				@t_id = BSON::ObjectId.new
				5.times do 
					cart_item = Shopping::CartItem.new(attributes_for(:cart_item))
					cart_item.resource_id = @u.id.to_s
					cart_item.parent_id = @t_id
					cart_item.save
					@created_cart_item_ids << cart_item.id.to_s
				end

			end

			after(:example) do 
				Shopping::CartItem.delete_all
			end


			##scenario -> add a few new cart items, but also add name on transaction, and remove some of the older cart items

			it " -- changes name on all cart items, and adds the new cart items, and removes the required cart items." do 

				##this is the new cart item to be added
				cart_item = Shopping::CartItem.new(attributes_for(:cart_item))
				cart_item.resource_id = @u.id.to_s
				cart_item.save

				##the cart item to be removed
				id_to_remove = @created_cart_item_ids.last

				##notes to be added to all cart items.
				@notes = "aies blood test when she was not well"

				put shopping_transaction_path({:id => @t_id}), {transaction: {add_cart_item_ids: [cart_item.id.to_s], remove_cart_item_ids: [id_to_remove], cart_items: {parent_notes: @notes}},:api_key => @ap_key, :current_app_id => "test_app_id"}.to_json, @headers

				
				cart_items = Shopping::CartItem.where(:parent_id => @t_id)
				##check that the cart item was successfully removed
				##check that the notes are present on each cart item.
				cart_items_map = Hash[cart_items.map{|c| c.id.to_s}.zip(cart_items)]
				
				cart_items.each do |c_item|
					expect(c_item.parent_notes).to eq(@notes)
				end
				##the item to be added should be there.
				expect(cart_items_map[cart_item.id.to_s]).not_to be_nil
				##the item to be removed should not be there
				expect(cart_items_map[id_to_remove]).to be_nil
				##the total length should be five.
				expect(cart_items_map.size).to eq(5)
			end


		end


		context " -- destroy -- ", transaction_destroy: true do 

			before(:example) do 
				@created_cart_item_ids = []
				##create a transaction on each of them.
				@t_id = BSON::ObjectId.new
				5.times do 
					cart_item = Shopping::CartItem.new(attributes_for(:cart_item))
					cart_item.resource_id = @u.id.to_s
					cart_item.parent_id = @t_id
					cart_item.save
					@created_cart_item_ids << cart_item.id.to_s
				end

			end

			after(:example) do 
				Shopping::CartItem.delete_all
			end

			it " -- destroys the transaction " do 

				delete shopping_transaction_path({:id => @t_id}),{:api_key => @ap_key, :current_app_id => "test_app_id"}.to_json, @headers

				cart_items = Shopping::CartItem.where(:parent_id => @t_id)

				expect(cart_items.size).to eq(0)

			end

		end

		context " -- show"  do 

			before(:example) do 
				@created_cart_item_ids = []
				##create a transaction on each of them.
				@t_id = BSON::ObjectId.new
				5.times do 
					cart_item = Shopping::CartItem.new(attributes_for(:cart_item))
					cart_item.resource_id = @u.id.to_s
					cart_item.parent_id = @t_id
					cart_item.save
					@created_cart_item_ids << cart_item.id.to_s
				end

			end

			after(:example) do 
				Shopping::CartItem.delete_all
			end

			it " -- shows the array fo cart items in the transaction " do 

				get shopping_transaction_path({:id => @t_id}),{:api_key => @ap_key, :current_app_id => "test_app_id"},@headers
				jresp = JSON.parse(response.body)
				jresp_cart_items = jresp.map{|c| c = Shopping::CartItem.new(c)}
				jresp_hash = Hash[jresp_cart_items.map{|c| c = c.id.to_s}.zip(jresp_cart_items)]
				@created_cart_item_ids.each do |c|
					expect(jresp_hash[c]).not_to be_nil
				end
			end

		end

	end		

end

