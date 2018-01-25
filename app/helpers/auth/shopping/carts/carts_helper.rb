module Auth::Shopping::Carts::CartsHelper

	## get /new
	def new_cart_path
      main_app.send(Auth::OmniAuth::Path.new_path(Auth.configuration.cart_class))
    end

    ## (PUT/PATCH/GET) - individual cart
    def cart_path(cart)
    	
    	main_app.send(Auth::OmniAuth::Path.show_or_update_or_delete_path(Auth.configuration.cart_class),cart)
    end

	
	##/carts (GET - all carts /CREATE - individual cart) 
	def carts_path
    	main_app.send(Auth::OmniAuth::Path.create_or_index_path(Auth.configuration.cart_class))
    end

    ##/shopping/carts/:id/edit
    def edit_cart_path(cart)
    	main_app.send(Auth::OmniAuth::Path.edit_path(Auth.configuration.cart_class),cart)
    end

end