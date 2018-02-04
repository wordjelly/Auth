module Auth::Shopping::DiscountsHelper

	###################################################
    ##
    ##
    ## PATH HELPERS.
    ##
    ##
    ###################################################

	## get /new
	def new_discount_path(options={})
      main_app.send(Auth::OmniAuth::Path.new_path(Auth.configuration.discount_class),options)
    end



    ## (PUT/PATCH/GET) - individual discount
    def discount_path(discount)
    	
    	main_app.send(Auth::OmniAuth::Path.show_or_update_or_delete_path(Auth.configuration.discount_class),discount)
    end

	
	##/discounts (GET - all discounts /CREATE - individual discount) 
	def discounts_path
    	main_app.send(Auth::OmniAuth::Path.create_or_index_path(Auth.configuration.discount_class))
    end

    ##/shopping/discounts/:id/edit
    def edit_discount_path(discount)
    	main_app.send(Auth::OmniAuth::Path.edit_path(Auth.configuration.discount_class),discount)
    end

end
