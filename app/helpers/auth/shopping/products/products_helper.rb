module Auth::Shopping::Products::ProductsHelper

	## get /new
	def new_product_path
      main_app.send(Auth::OmniAuth::Path.new_path(Auth.configuration.product_class))
    end

    ## (PUT/PATCH/GET) - individual product
    def product_path(product)
    	
    	main_app.send(Auth::OmniAuth::Path.show_or_update_or_delete_path(Auth.configuration.product_class),product)
    end

	
	##/products (GET - all products /CREATE - individual product) 
	def products_path
    	main_app.send(Auth::OmniAuth::Path.create_or_index_path(Auth.configuration.product_class))
    end

    ##/shopping/products/:id/edit
    def edit_product_path(product)
    	main_app.send(Auth::OmniAuth::Path.edit_path(Auth.configuration.product_class),product)
    end

end