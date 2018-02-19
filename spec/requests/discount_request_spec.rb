require "rails_helper"

RSpec.describe "discount request spec",:discount => true,:shopping => true, :type => :request do 

	before(:all) do 
        ActionController::Base.allow_forgery_protection = false
        User.delete_all
        Auth::Client.delete_all
        
        Shopping::CartItem.delete_all
        Shopping::Product.delete_all
        
        @u = User.new(attributes_for(:user_confirmed))
        @u.save

        @u2 = User.new(attributes_for(:user_confirmed))
        @u.save

        @u3 = User.new(attributes_for(:user_confirmed))
        @u3.save

        ## THIS PRODUCT IS USED IN THE CART_ITEM FACTORY, TO PROVIDE AND ID.
        @product = Shopping::Product.new(:name => "test product", :price => 10.00)
       
        @product.save


        @c = Auth::Client.new(:resource_id => @u.id, :api_key => "test", :app_ids => ["test_app_id"])
        @c.redirect_urls = ["http://www.google.com"]
        @c.versioned_create
        @u.client_authentication["test_app_id"] = "test_es_token"
        @u.save
        @u2.client_authentication["test_app_id"] = "test_es_token2"
        @u2.save

        @u3.client_authentication["test_app_id"] = "test_es_token3"
        @u3.save

        @ap_key = @c.api_key
        @headers = { "CONTENT_TYPE" => "application/json" , "ACCEPT" => "application/json", "X-User-Token" => @u.authentication_token, "X-User-Es" => @u.client_authentication["test_app_id"], "X-User-Aid" => "test_app_id"}
        

        @u2_headers = { "CONTENT_TYPE" => "application/json" , "ACCEPT" => "application/json", "X-User-Token" => @u2.authentication_token, "X-User-Es" => @u2.client_authentication["test_app_id"], "X-User-Aid" => "test_app_id"}

        @u3_headers = { "CONTENT_TYPE" => "application/json" , "ACCEPT" => "application/json", "X-User-Token" => @u3.authentication_token, "X-User-Es" => @u3.client_authentication["test_app_id"], "X-User-Aid" => "test_app_id"}
        
        ### CREATE ONE ADMIN USER

        ### It will use the same client as the user.
        @admin = Admin.new(attributes_for(:admin_confirmed))
        @admin.client_authentication["test_app_id"] = "test_es_token"
        @admin.save
        @admin_headers = { "CONTENT_TYPE" => "application/json" , "ACCEPT" => "application/json", "X-Admin-Token" => @admin.authentication_token, "X-Admin-Es" => @admin.client_authentication["test_app_id"], "X-Admin-Aid" => "test_app_id"}
        
    end

	context " -- json requests -- " do 
		before(:example) do 
			Shopping::CartItem.delete_all
			Shopping::Cart.delete_all
			Shopping::Payment.delete_all
			Shopping::Discount.delete_all
		end
		

		context " -- normal flow -- " do 

			it " -- user creates a discount coupon, after successfull payment -- " do 

				cart_items = create_cart_items(@u)
				
				cart = create_cart(@u)
				
				add_cart_items_to_cart(cart_items,cart,@u)
				
				payment = create_payment(cart,50,@u)
				
				authorize_payment_as_admin(payment,@admin)

				discount = build_discount_for_request(cart)
				
				post shopping_discounts_path,{discount: discount,:api_key => @ap_key, :current_app_id => "test_app_id"}.to_json, @headers

				expect(response.code).to eq("201")
				expect(Shopping::Discount.count).to eq(1)

			end

			it " -- signed out user can view the discount coupon -- ", :view_discount => true do 

				cart_items = create_cart_items(@u)
				
				cart = create_cart(@u)
				
				add_cart_items_to_cart(cart_items,cart,@u)
				
				payment = create_payment(cart,50,@u)
				
				authorize_payment_as_admin(payment,@admin)					
				discount = create_discount(cart,@u)

				get shopping_discount_path({:id => discount.id.to_s}),{:api_key => @ap_key, :current_app_id => "test_app_id"}.to_json, { "CONTENT_TYPE" => "application/json" , "ACCEPT" => "application/json"}					

				discount_obj = JSON.parse(response.body)

				expect(discount_obj["discount_amount"]).to eq(discount.discount_amount)

			end

			it " -- same user cannot create cart items using the discount -- " do 

			end

			it " -- calling create multiple cart items twice, what happens -- " do 

			end

			it " -- signed in user can create cart items from the coupon -- ", :multi_citem => true do 

				cart_items = create_cart_items(@u)
				
				cart = create_cart(@u)
				
				add_cart_items_to_cart(cart_items,cart,@u)
				
				payment = create_payment(cart,50,@u)
				
				authorize_payment_as_admin(payment,@admin)					
				discount = create_discount(cart,@u)

				post create_multiple_shopping_cart_items_path, {:id => discount.id.to_s, discount: { :product_ids => discount.product_ids},:api_key => @ap_key, :current_app_id => "test_app_id"}.to_json, @u2_headers

				expect(response.code).to eq("200")

				json_array_of_cart_items = JSON.parse(response.body)
				expect(json_array_of_cart_items.size).to eq(5)

				expect(Shopping::CartItem.count).to eq(10)

			end

			it " -- signed in user can create a cart from those cart items -- " do 


				cart_items = create_cart_items(@u)
				
				cart = create_cart(@u)
				
				add_cart_items_to_cart(cart_items,cart,@u)
				
				payment = create_payment(cart,50,@u)
				
				authorize_payment_as_admin(payment,@admin)					
				discount = create_discount(cart,@u)

				multiple_created_cart_items = create_multiple_cart_items(discount,@u2)

				expect(Shopping::CartItem.count).to eq(10)

				post shopping_carts_path,{cart: {add_cart_item_ids: multiple_created_cart_items.map{|c| c = c.id.to_s}},:api_key => @ap_key, :current_app_id => "test_app_id"}.to_json, @u2_headers

				expect(response.code).to eq("201")

				expect(Shopping::Cart.count).to eq(2)
			end


			it " -- signed in user, is shown option to 	pay for cart with coupon -- " do 

				## make a payment using the discount id.
				cart_items = create_cart_items(@u)
				
				cart = create_cart(@u)
				
				add_cart_items_to_cart(cart_items,cart,@u)
				
				payment = create_payment(cart,50,@u)
				
				authorize_payment_as_admin(payment,@admin)					
				discount = create_discount(cart,@u)

				multiple_created_cart_items = create_multiple_cart_items(discount,@u2)

				user_two_cart = create_cart(@u2)

				add_cart_items_to_cart(multiple_created_cart_items,user_two_cart,@u2)

				
				post shopping_payments_path, {cart_id: user_two_cart.id.to_s,payment_type: "cash", amount: 0.0, discount_id: discount.id.to_s, :api_key => @ap_key, :current_app_id => "test_app_id"}.to_json, @u2_headers

				expect(response.code).to eq("201")
				payment_created = assigns(:auth_shopping_payment)
				expect(payment_created.payment_status).to be_nil
			end

			it " -- cart id shows up in the to_be_verified array of the discount object. -- " do 

				cart_items = create_cart_items(@u)
				
				cart = create_cart(@u)
				
				add_cart_items_to_cart(cart_items,cart,@u)
				
				payment = create_payment(cart,50,@u)
				
				authorize_payment_as_admin(payment,@admin)					
				discount = create_discount(cart,@u)

				multiple_created_cart_items = create_multiple_cart_items(discount,@u2)

				user_two_cart = create_cart(@u2)

				add_cart_items_to_cart(multiple_created_cart_items,user_two_cart,@u2)

				
				discount_payment = create_payment_using_discount(discount,user_two_cart,@u2)

				get shopping_discount_path({:id => discount.id.to_s}),{:api_key => @ap_key, :current_app_id => "test_app_id"}.to_json, { "CONTENT_TYPE" => "application/json" , "ACCEPT" => "application/json"}		

				discount_obj = JSON.parse(response.body)

				puts discount_obj.to_s

				pending = discount_obj["pending"]
				
				expect(pending.include? discount_payment.id.to_s).to be_truthy

			end

			it " -- coupon creator an verify the payment -- ", :verify_discount do 
				
				cart_items = create_cart_items(@u)
				
				cart = create_cart(@u)
				
				add_cart_items_to_cart(cart_items,cart,@u)
				
				payment = create_payment(cart,50,@u)
				
				authorize_payment_as_admin(payment,@admin)					
				discount = create_discount(cart,@u)

				multiple_created_cart_items = create_multiple_cart_items(discount,@u2)

				user_two_cart = create_cart(@u2)

				add_cart_items_to_cart(multiple_created_cart_items,user_two_cart,@u2)

				
				discount_payment = create_payment_using_discount(discount,user_two_cart,@u2)


				put shopping_discount_path({:id => discount.id.to_s}), {:discount => {:add_verified_ids => [discount_payment.id.to_s]}, :api_key => @ap_key, :current_app_id => "test_app_id"}.to_json,@headers

				puts response.body.to_s

				expect(response.code).to eq("204")
				discount = Shopping::Discount.find(discount.id.to_s)
				expect(discount.verified.include? discount_payment.id.to_s).to be_truthy
				expect(discount.pending).to be_empty

			end

			

			it " -- payment creator can verify and view the that his payment is now verified -- " do 

				## payment should pass now as successfull

				cart_items = create_cart_items(@u)
				
				cart = create_cart(@u)
				
				add_cart_items_to_cart(cart_items,cart,@u)
				
				payment = create_payment(cart,50,@u)
				
				authorize_payment_as_admin(payment,@admin)					
				discount = create_discount(cart,@u)

				multiple_created_cart_items = create_multiple_cart_items(discount,@u2)

				user_two_cart = create_cart(@u2)

				add_cart_items_to_cart(multiple_created_cart_items,user_two_cart,@u2)

				
				discount_payment = create_payment_using_discount(discount,user_two_cart,@u2)

				approve_pending_discount_request(discount,discount_payment,@u,user=nil)

				##now call update on the discount payment as user u2, and it should have a payment status as passed.
				put shopping_payment_path({:id => discount_payment.id.to_s}), {:is_verify_payment => true, :api_key => @ap_key, :current_app_id => "test_app_id"}.to_json,@u2_headers

				expect(response.code).to eq("204")
				discount_payment = Shopping::Payment.find(discount_payment.id.to_s)
				expect(discount_payment.payment_status).to eq(1)

			end

		end


		context " -- discount creation not permitted if -- " do 

			it " -- does not create discount if some items are still waiting to be accepted in the cart. -- ", :discount_na_pending_items do 

				cart_items = create_cart_items(@u)
				
				cart = create_cart(@u)
				
				add_cart_items_to_cart(cart_items,cart,@u)
				
				puts "doing create payment."
				payment = create_payment(cart,1,@u)
						
				puts "at this stage all these cart items had a status of null"
				puts "now at this stage, they should have been found."
				puts "doing authorize payment."
				authorize_payment_as_admin(payment,@admin)

				## now should not create the discount
				discount = build_discount_for_request(cart)
				
				post shopping_discounts_path,{discount: discount,:api_key => @ap_key, :current_app_id => "test_app_id"}.to_json, @headers

				#expect(response.code).to eq("201")
				response_body = JSON.parse(response.body)
				puts response_body.to_s
				expect(Shopping::Discount.count).to eq(0)

			end

		end

		context " -- use of generic discount coupons, not backed by cart -- ", :cartless => true do 

			before(:example) do 
				@discount = build_cartless_productless_discount

			end

			context " -- admin -- " do 

				it " -- creates a discount without a cart, or product ids -- " do

					
					post shopping_discounts_path,{discount: @discount,:api_key => @ap_key, :current_app_id => "test_app_id"}.to_json, @admin_headers

					#puts response.body.to_s

					#discount_created = Shopping::Discount.find(@discount.id.to_s)

					expect(response.code).to eq("201")
					expect(Shopping::Discount.count).to eq(1)
					#expect(discount_created.discount_amount).to eq(@discount.amount)

				end

			
				it " -- user can use the cartless discount for his payments -- " do 

					cart_items = create_cart_items(@u)
				
					cart = create_cart(@u)
				
					add_cart_items_to_cart(cart_items,cart,@u)

					discount =create_cartless_productless_discount(@admin)

					## now make a payment using the discount id, provided above.
					post shopping_payments_path, {cart_id: cart.id.to_s,payment_type: "cash", amount: 0.0, discount_id: discount.id.to_s, :api_key => @ap_key, :current_app_id => "test_app_id"}.to_json, @headers

					## expect the payment to have gone through.
					expect(response.code).to eq("201")

					expect(Shopping::Payment.count).to eq(1)

					payment_hash = JSON.parse(response.body)

					expect(payment_hash["payment_status"]).to eq(1)

				end

			end

			context " -- non admin user  -- " do 

				it "--  cannot create a discount -- " do 

					post shopping_discounts_path,{discount: @discount,:api_key => @ap_key, :current_app_id => "test_app_id"}.to_json, @headers

					#puts response.body.to_s

					#discount_created = Shopping::Discount.find(@discount.id.to_s)

					expect(response.code).to eq("422")
					expect(Shopping::Discount.count).to eq(0)

				end
			end

		end

		context " -- payment previously verified, is now set as false -- " do 

			before(:example) do 

				Shopping::Cart.delete_all
				Shopping::CartItem.delete_all
				Shopping::Payment.delete_all
				Shopping::Discount.delete_all

				


			end

			context " -- 1 discount was already created and used, 1 discount has been added as pending.  -- " do 

				before(:example) do 

					@cart_items = create_cart_items(@u)
				
					@cart = create_cart(@u)
				
					add_cart_items_to_cart(@cart_items,@cart,@u)
				
					@payment = create_payment(@cart,50,@u)
				
					authorize_payment_as_admin(@payment,@admin)					

					@discount = create_discount(@cart,@u)

					@multiple_created_cart_items = create_multiple_cart_items(@discount,@u2)

					@user_two_cart = create_cart(@u2)

					add_cart_items_to_cart(@multiple_created_cart_items,@user_two_cart,@u2)

					@discount_payment = create_payment_using_discount(@discount,@user_two_cart,@u2)

					approve_pending_discount_request(@discount,@discount_payment,@u)
					
					## the second user utilizes the discount
					@discount_payment = use_discount(@discount_payment,@u2)

					## now create a new user, and have him try to make a payment using the discount coupon.
					@multiple_created_cart_items_for_user_3 = create_multiple_cart_items(@discount,@u3)

					@user_three_cart = create_cart(@u3)

					add_cart_items_to_cart(@multiple_created_cart_items_for_user_3,@user_three_cart,@u3)

					@discount_payment_three = create_payment_using_discount(@discount,@user_three_cart,@u3)

					## now update the original payment as failed.
					update_payment_as_failed(@payment,@admin)					

				end

				it " -- doesn't allow new payment request to be converted into a verified request -- ", :conv => true do 

					put shopping_discount_path({:id => @discount.id.to_s}), {:discount => {:add_verified_ids => [@discount_payment_three.id.to_s]}, :api_key => @ap_key, :current_app_id => "test_app_id"}.to_json,@headers

					puts response.body.to_s

					expect(response.code).to eq("422")
					discount = Shopping::Discount.find(@discount.id.to_s)
					expect(discount.verified.include? @discount_payment_three.id.to_s).not_to be_truthy
					expect(discount.pending).not_to be_empty


				end


			end

			context " -- discount doesnt need verification -- " do 

				before(:example) do 

					@cart_items = create_cart_items(@u)
				
					@cart = create_cart(@u)
				
					add_cart_items_to_cart(@cart_items,@cart,@u)
				
					@payment = create_payment(@cart,50,@u)
				
					authorize_payment_as_admin(@payment,@admin)					

					## so this discount doesnt need verification
					@discount = create_discount(@cart,@u,nil,false)

					@multiple_created_cart_items = create_multiple_cart_items(@discount,@u2)

					@user_two_cart = create_cart(@u2)

					add_cart_items_to_cart(@multiple_created_cart_items,@user_two_cart,@u2)

					@discount_payment = create_payment_using_discount(@discount,@user_two_cart,@u2)

					approve_pending_discount_request(@discount,@discount_payment,@u)
					
					## the second user utilizes the discount
					@discount_payment = use_discount(@discount_payment,@u2)

					## now create a new user, and have him try to make a payment using the discount coupon.
					@multiple_created_cart_items_for_user_3 = create_multiple_cart_items(@discount,@u3)

					@user_three_cart = create_cart(@u3)

					add_cart_items_to_cart(@multiple_created_cart_items_for_user_3,@user_three_cart,@u3)

					
					## now update the original payment as failed.
					update_payment_as_failed(@payment,@admin)					

				end

				it " -- doesnt allow creation of any discount payments -- ", :conv => true do 

					#@discount_payment_three = create_payment_using_discount(@discount,@user_three_cart,@u3)
					post shopping_payments_path, {cart_id: @user_three_cart.id.to_s,payment_type: "cash", amount: 0.0, discount_id: @discount.id.to_s, :api_key => @ap_key, :current_app_id => "test_app_id"}.to_json, @u3_headers

					expect(response.code).to eq("201")
					payment_created = assigns(:auth_shopping_payment)
					expect(payment_created.payment_status).to eq(0)

				end

			end

		end

		context " -- refund -- " do 

			it " -- discount payment is considered during the calculation of cart pending balance -- ", :discount_refund => true do 

				## first create a discount, then use it as a user
				## then have a cart item removed.
				## then let him make a refund request.
				cart_items = create_cart_items(@u)
				
				cart = create_cart(@u)
				
				add_cart_items_to_cart(cart_items,cart,@u)

				payment = create_payment(cart,50,@u)
				
				authorize_payment_as_admin(payment,@admin)					
				discount = create_discount(cart,@u)

				multiple_created_cart_items = create_multiple_cart_items(discount,@u2)

				user_two_cart = create_cart(@u2)

				add_cart_items_to_cart(multiple_created_cart_items,user_two_cart,@u2)

				discount_payment = create_payment_using_discount(discount,user_two_cart,@u2)

				approve_pending_discount_request(discount,discount_payment,@u,user=nil)

				## the second user utilizes the discount
				discount_payment = use_discount(discount_payment,@u2)


				## now remove some items from the cart of the second user as an admin.
				cart_item_to_remove = multiple_created_cart_items.first
            	cart_item_to_remove.signed_in_resource = @admin
            	k = cart_item_to_remove.unset_cart

            	## now make a refund request
            	## it should fail.
            	post shopping_payments_path, {cart_id: user_two_cart.id.to_s,payment_type: "cash", refund: true, amount: -10, :api_key => @ap_key, :current_app_id => "test_app_id"}.to_json, @u2_headers   

            	expect(response.code).to eq("422")
            	puts response.body.to_s

			end

		end

		
	end


end