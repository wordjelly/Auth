class Auth::Shopping::ShoppingController < Auth::ApplicationController

	include Auth::Concerns::DeviseConcern
	include Auth::Concerns::TokenConcern

    before_filter :do_before_request  , :only => [:create,:update,:destroy,:show,:index, :new]
    before_filter :initialize_vars, :only => [:create,:update,:destroy,:show,:index, :new]

    def instantiate_cart_class
		if @cart_class = Auth.configuration.cart_class
	      begin
	        @cart_class = @cart_class.constantize
	      rescue
	        not_found("error instantiating class from cart class")
	      end
	    else
	      not_found("cart class not specified in configuration")
	    end
	end


	def instantiate_cart_item_class

	    if @cart_item_class = Auth.configuration.cart_item_class
	      begin
	        @cart_item_class = @cart_item_class.constantize
	      rescue
	        not_found("error instatiating class from cart item class")
	      end
	    else
	      not_found("cart item class not specified in configuration")
	    end

	end


	def instantiate_payment_class

		if @payment_class = Auth.configuration.payment_class
	      begin
	        @payment_class = @payment_class.constantize
	      rescue
	        not_found("error instatiating class from payment class")
	      end
	    else
	      not_found("payment class not specified in configuration")
	    end

	end

	def instantiate_product_class

		if @product_class = Auth.configuration.payment_class
	      begin
	        @product_class = @product_class.constantize
	      rescue
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
	end


	def check_for_update(obj)
		not_found if obj.nil?
    	not_found("please provide a valid id for the update") if obj.new_record?
	end

	def check_for_create(obj)
		not_found if obj.nil?
		obj.new_record? or not_found("this is not a new record")
	end
  	
	def check_for_destroy(obj)
		not_found("please provide a cart id") if obj.new_record?
	end

end