module Auth::Shopping::CartItems::CartItemsHelper

	## get /new
	def new_cart_item_path
      main_app.send(Auth::OmniAuth::Path.new_path(Auth.configuration.cart_item_class))
    end

    ## (PUT/PATCH/GET) - individual cart_item
    def cart_item_path(cart_item)
    	
    	main_app.send(Auth::OmniAuth::Path.show_or_update_or_delete_path(Auth.configuration.cart_item_class),cart_item)
    end

	
	##/cart_items (GET - all cart_items /CREATE - individual cart_item) 
	def cart_items_path
    	main_app.send(Auth::OmniAuth::Path.create_or_index_path(Auth.configuration.cart_item_class))
    end

    ##/shopping/cart_items/:id/edit
    def edit_cart_item_path(cart_item)
    	main_app.send(Auth::OmniAuth::Path.edit_path(Auth.configuration.cart_item_class),cart_item)
    end

    def create_multiple_cart_items_path(options={})
        main_app.send("create_multiple_" + Auth.configuration.cart_item_class.underscore.pluralize.gsub("\/","_")+ "_path",options)
    end

end