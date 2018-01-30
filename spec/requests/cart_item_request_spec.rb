require "rails_helper"

RSpec.describe "cart item request spec",:cart_item => true,:shopping => true, :type => :request do 

	before(:all) do 
        ActionController::Base.allow_forgery_protection = false
        User.delete_all
        Auth::Client.delete_all
        Shopping::CartItem.delete_all
        Shopping::Product.delete_all
        
        ## THIS PRODUCT IS USED IN THE CART_ITEM FACTORY, TO PROVIDE AND ID.
        @product = Shopping::Product.new(:name => "test product", :price => 400.00)
       
        @product.save

        @u = User.new(attributes_for(:user_confirmed))
        @u.save

        @c = Auth::Client.new(:resource_id => @u.id, :api_key => "test", :app_ids => ["test_app_id"])
        @c.redirect_urls = ["http://www.google.com"]
        @c.versioned_create
        @u.client_authentication["test_app_id"] = "test_es_token"
        @u.save
        @ap_key = @c.api_key
        @headers = { "CONTENT_TYPE" => "application/json" , "ACCEPT" => "application/json", "X-User-Token" => @u.authentication_token, "X-User-Es" => @u.client_authentication["test_app_id"], "X-User-Aid" => "test_app_id"}
        


        ### CREATE ONE ADMIN USER

        ### It will use the same client as the user.
        @admin = Admin.new(attributes_for(:admin_confirmed))
        @admin.client_authentication["test_app_id"] = "test_es_token"
        @admin.save
        @admin_headers = { "CONTENT_TYPE" => "application/json" , "ACCEPT" => "application/json", "X-Admin-Token" => @admin.authentication_token, "X-Admin-Es" => @admin.client_authentication["test_app_id"], "X-Admin-Aid" => "test_app_id"}
        
    end



    context " -- json requests -- " do 

    	before(:each) do 
    		Shopping::CartItem.delete_all
    	end	

    	context " -- show --" do 

    		it " -- shows the cart item -- ", :show_cart_item do 

    			cart_item = Shopping::CartItem.new(attributes_for(:cart_item))
				cart_item.resource_id = @u.id.to_s
				cart_item.resource_class = @u.class.name.to_s
				cart_item.signed_in_resource = @admin
				res = cart_item.save

    			get shopping_cart_item_path({:id => cart_item.id.to_s}),{:api_key => @ap_key, :current_app_id => "test_app_id"}, @headers
    			
    		end

    	end
	
		context " -- create --" do 

			it " -- creates cart item with all permitted params,and assigns user id. ",:c1 => true do 
				cart_item = attributes_for(:cart_item)

				post shopping_cart_items_path,{cart_item: cart_item,:api_key => @ap_key, :current_app_id => "test_app_id"}.to_json, @headers
				
	            @cart_item_created = assigns(:auth_shopping_cart_item)
	            #puts "cart item created is: #{@cart_item_created}"
	            cart_item_hash = JSON.parse(response.body)
	            


	            expect(@cart_item_created.resource_id).to eq(@u.id.to_s)
	            expect(@cart_item_created.price).to eq(Shopping::Product.first.price)
	            expect(@cart_item_created.name).to eq(Shopping::Product.first.name)

	            #puts cart_item.to_s

	            expect(@cart_item_created.quantity).to eq(cart_item[:quantity])
	            expect(@cart_item_created.discount_code).to eq(cart_item[:discount_code])
			end

		end

		context "-- update" do 

			it " -- only updates discount and quantity ",:update_only => true do 
				
				
				cart_item = Shopping::CartItem.new(attributes_for(:cart_item))
				cart_item.resource_id = @u.id.to_s
				cart_item.resource_class = @u.class.name.to_s
				cart_item.signed_in_resource = @admin
				res = cart_item.save
				
				
	            a = {:cart_item => {:discount => 42, :quantity => 10, :product_id => BSON::ObjectId.new.to_s, :price => 400}, api_key: @ap_key, :current_app_id => "test_app_id"}
	            
	            ##have to post to the id url.
	            put shopping_cart_item_path({:id => cart_item.id.to_s}), a.to_json,@headers
	           

				updated_cart_item = assigns(:auth_shopping_cart_item)
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
				cart_item.resource_class = @u.class.name
				cart_item.signed_in_resource = @admin
				cart_item.save
				
	            a = {:cart_item => {:discount => 42, :quantity => 10, :product_id => BSON::ObjectId.new.to_s, :price => 400}, api_key: @ap_key, :current_app_id => "test_app_id"}
	            @headers = { "CONTENT_TYPE" => "application/json" , "ACCEPT" => "application/json", "X-User-Token" => @u1.authentication_token, "X-User-Es" => @u1.client_authentication["test_app_id"], "X-User-Aid" => "test_app_id"}
	            ##have to post to the id url.
	            put shopping_cart_item_path({:id => cart_item.id.to_s}), a.to_json,@headers
	            resp = JSON.parse(response.body)
	            expect(resp.keys).to include("errors")
			end	
			
		end

		context " -- cart item and payment interaction -- " do 

			before(:example) do 
	            
	            Shopping::CartItem.delete_all
	            Shopping::Cart.delete_all
	            Shopping::Payment.delete_all
	            @created_cart_item_ids = []
	            @cart = Shopping::Cart.new
	            @cart.resource_id = @u.id.to_s
	            @cart.resource_class = @u.class.name
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
	            Shopping::Cart.delete_all
	            Shopping::Payment.delete_all
	        
	        end


			it " -- auto updates the cart item status as not accepted, if the accepting payment doesnt exists -- ", :citem_payment_delete do 


				## create and save a payment for this entire cart.
				payment = Shopping::Payment.new
		        payment.payment_type = "cash"
		        payment.amount = 50.00
		        payment.resource_id = @u.id.to_s
		        payment.resource_class = @u.class.name.to_s
		        payment.cart_id = @cart.id.to_s
		        payment.signed_in_resource = @admin
		        ## this is setting the payment as successfully.
		        payment.payment_status = 1
		        ps = payment.save
		        
		        expect(ps).to be_truthy


		        ## this should cause all the cart item statuses to get accepted.
		        @created_cart_item_ids.each do |cid|
		        	citem = Shopping::CartItem.find(cid)
		        	expect(citem.accepted).to be_truthy
		        end

				## then delete the payment.
				l = payment.delete
				
				## now call update on the first cart item with no payment.
				put shopping_cart_item_path({:id => @created_cart_item_ids.first}), {api_key: @ap_key, :current_app_id => "test_app_id"}.to_json,@headers


				## expect the cart item to have accepted set to false.
				citem = Shopping::CartItem.find(@created_cart_item_ids.first)
				expect(citem.accepted == false).to be_truthy

			end


			it " -- user cannot remove cart item after payment has been made -- " do 

				

			end

		end


		context " -- destroy -- " do 

			it  " -- returns 204 " do 
				cart_item = Shopping::CartItem.new(attributes_for(:cart_item))
				cart_item.resource_id = @u.id.to_s
				cart_item.resource_class = @u.class.name.to_s
				cart_item.signed_in_resource = @admin
				cart_item.save
				@headers = { "CONTENT_TYPE" => "application/json" , "ACCEPT" => "application/json", "X-User-Token" => @u.authentication_token, "X-User-Es" => @u.client_authentication["test_app_id"], "X-User-Aid" => "test_app_id"}
				delete shopping_cart_item_path({:id => cart_item.id.to_s}),{api_key: @ap_key, :current_app_id => "test_app_id"}.to_json,@headers
				expect(response.code).to eq("204")
				expect(response.body).to be_empty
			end


			it " -- doesn't allow destroy if status is accepted -- ", :delete_accepted_cart_item do 

				cart_item = Shopping::CartItem.new(attributes_for(:cart_item))
				cart_item.resource_id = @u.id.to_s
				cart_item.resource_class = @u.class.name.to_s
				cart_item.accepted = true
				cart_item.signed_in_resource = @admin
				cart_item.save
				@headers = { "CONTENT_TYPE" => "application/json" , "ACCEPT" => "application/json", "X-User-Token" => @u.authentication_token, "X-User-Es" => @u.client_authentication["test_app_id"], "X-User-Aid" => "test_app_id"}
				delete shopping_cart_item_path({:id => cart_item.id.to_s}),{api_key: @ap_key, :current_app_id => "test_app_id"}.to_json,@headers

				shopping_cart_item_ids = Shopping::CartItem.all.map{|c| c = c.id.to_s}

				expect(shopping_cart_item_ids.include? cart_item.id.to_s).to be_truthy

			end
			
		end

		context " -- index " do 

			it " -- returns the cart items belonging to this user ", :problem_now => true do 
				created_cart_item_ids = []
				5.times do 
					cart_item = Shopping::CartItem.new(attributes_for(:cart_item))
					cart_item.resource_id = @u.id.to_s
					cart_item.resource_class = @u.class.name
					cart_item.signed_in_resource = @admin
					cart_item.save
					created_cart_item_ids << cart_item.id.to_s
				end
				@headers = { "CONTENT_TYPE" => "application/json" , "ACCEPT" => "application/json", "X-User-Token" => @u.authentication_token, "X-User-Es" => @u.client_authentication["test_app_id"], "X-User-Aid" => "test_app_id"}
				get shopping_cart_items_path({api_key: @ap_key, :current_app_id => "test_app_id"}),nil,@headers
				returned_objects = JSON.parse(response.body)
				expect(returned_objects).not_to be_empty
				expect(returned_objects.size).to eq(5)
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


			it " -- return unauthorized trying to access index action without a valid user -- " do 

				@headers = { "CONTENT_TYPE" => "application/json" , "ACCEPT" => "application/json"}

				get shopping_cart_items_path({api_key: @ap_key, :current_app_id => "test_app_id"}),nil,@headers

				expect(response.code).to eq("401")

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
				cart_item.resource_class = @u.class.name
				cart_item.signed_in_resource = @admin
				cart_item.save
				
	            @headers = { "CONTENT_TYPE" => "application/json" , "ACCEPT" => "application/json", "X-User-Token" => @u2.authentication_token, "X-User-Es" => @u2.client_authentication["test_app_id"], "X-User-Aid" => "test_app_id"}
	            get shopping_cart_item_path({:id => cart_item.id.to_s,api_key: @ap_key, :current_app_id => "test_app_id"}),nil,@headers

	            response_hash = JSON.parse(response.body)

	            

	            expect(response_hash["errors"]).to eq("Not Found")

			end

		end

	end

end
