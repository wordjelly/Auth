class Auth::Shopping::ShoppingController < Auth::ApplicationController

	
	def instantiate_discount_class
		if @auth_shopping_discount_class = Auth.configuration.discount_class
	      begin
	        @auth_shopping_discount_class = @auth_shopping_discount_class.constantize
	      rescue
	        not_found("error instantiating class from discount class")
	      end
	    else
	      not_found("discount class not specified in configuration")
	    end
	end


    def instantiate_cart_class
		if @auth_shopping_cart_class = Auth.configuration.cart_class
	      begin
	        @auth_shopping_cart_class = @auth_shopping_cart_class.constantize
	      rescue
	        not_found("error instantiating class from cart class")
	      end
	    else
	      not_found("cart class not specified in configuration")
	    end
	end


	def instantiate_cart_item_class

	    if @auth_shopping_cart_item_class = Auth.configuration.cart_item_class
	      begin
	        @auth_shopping_cart_item_class = @auth_shopping_cart_item_class.constantize
	      rescue
	        not_found("error instatiating class from cart item class")
	      end
	    else
	      not_found("cart item class not specified in configuration")
	    end

	end


	def instantiate_payment_class

		if @auth_shopping_payment_class = Auth.configuration.payment_class
	      begin
	        @auth_shopping_payment_class = @auth_shopping_payment_class.constantize
	      rescue
	        not_found("error instatiating class from payment class")
	      end
	    else
	      not_found("payment class not specified in configuration")
	    end

	end

	def instantiate_product_class

		if @auth_shopping_product_class = Auth.configuration.product_class
	      begin
	        @auth_shopping_product_class = @auth_shopping_product_class.constantize
	      rescue => e
	      	puts e.to_s
	        not_found("error instatiating class from product class")
	      end
	    else
	      not_found("product class not specified in configuration")
	    end

	end

	
	

	def instantiate_shopping_classes
		instantiate_payment_class
		instantiate_cart_class
		instantiate_cart_item_class
		instantiate_product_class
		instantiate_discount_class
	end


end