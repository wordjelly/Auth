module Auth::Shopping::Products::ProductsHelper


    ## @param[Auth::Shopping::Product] product
    ## @return[Auth::Shopping::CartItem] citem 
    def create_cart_item_from_product(product)
        citem = Auth.configuration.cart_item_class.constantize.new
        product.attributes.keys.each do |p_att|
            if citem.respond_to? p_att.to_sym
                unless (p_att == "_id" || p_att == "_type" || p_att == "resource_id" || p_att == "resource_class")  
                    citem.send("#{p_att}=",product.send("#{p_att}"))
                end
            end
        end
        citem.product_id = product.id.to_s
       
        citem
    end


    ##########################################################
    ##
    ##
    ## PATH HELPERS.
    ##
    ##
    ##########################################################


	## get /new
	def new_product_path
      main_app.send(Auth::OmniAuth::Path.new_path(Auth.configuration.product_class))
    end

    ## (PUT/PATCH/GET) - individual product
    def product_path(product)
    	
    	main_app.send(Auth::OmniAuth::Path.show_or_update_or_delete_path(Auth.configuration.product_class),product)
    end

	
	##/products (GET - all products /CREATE - individual product) 
	def products_path(params={})
    	main_app.send(Auth::OmniAuth::Path.create_or_index_path(Auth.configuration.product_class),params)
    end

    ##/shopping/products/:id/edit
    def edit_product_path(product)
    	main_app.send(Auth::OmniAuth::Path.edit_path(Auth.configuration.product_class),product)
    end

end