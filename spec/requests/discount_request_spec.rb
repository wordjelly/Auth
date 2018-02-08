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
        @ap_key = @c.api_key
        @headers = { "CONTENT_TYPE" => "application/json" , "ACCEPT" => "application/json", "X-User-Token" => @u.authentication_token, "X-User-Es" => @u.client_authentication["test_app_id"], "X-User-Aid" => "test_app_id"}
        

        @u2_headers = { "CONTENT_TYPE" => "application/json" , "ACCEPT" => "application/json", "X-User-Token" => @u2.authentication_token, "X-User-Es" => @u2.client_authentication["test_app_id"], "X-User-Aid" => "test_app_id"}
        
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
		context " -- with proxy -- " do 

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

				it " -- signed in user can create cart items from the coupon -- " do 

					cart_items = create_cart_items(@u)
					
					cart = create_cart(@u)
					
					add_cart_items_to_cart(cart_items,cart,@u)
					
					payment = create_payment(cart,50,@u)
					
					authorize_payment_as_admin(payment,@admin)					
					discount = create_discount(cart,@u)

					post create_multiple_shopping_cart_items_path, {:id => discount.id.to_s, discount: { :product_ids => discount.product_ids},:api_key => @ap_key, :current_app_id => "test_app_id"}.to_json, @u2_headers

					expect(response.code).to eq("200")
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

=begin
			context " -- discount creation not permitted if -- " do 

				it " -- cannot create discount unless minimum payable amount is satsifeid for cart -- " do 

				end

				it " -- cannot create discount if payment is unsuccessfull/pending, using that payment -- " do 

				end

			end
=end
=begin
			context " -- when base payment becomes unsuccessfull"

				it " -- cancels all related discounts -- " do 

				end

			end
=end
=begin
			context " -- delete -- " do 
				it " -- discount once created cannot be deleted -- " do 

				end
			end
=end
=begin
			context " -- discount and refund -- " do 
				it " -- refund amount does not include discount payments -- " do 

				end
			end
=end
		end	

	end


end