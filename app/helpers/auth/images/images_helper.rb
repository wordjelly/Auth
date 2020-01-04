module Auth::Images::ImagesHelper

	## get /new
	def new_image_path
      main_app.send(Auth::OmniAuth::Path.new_path(Auth.configuration.image_class))
    end

    ## (PUT/PATCH/GET) - individual image
    def image_path(image)
    	
    	main_app.send(Auth::OmniAuth::Path.show_or_update_or_delete_path(Auth.configuration.image_class),image)
    end

	
	##/images (GET - all images /CREATE - individual image) 
	def images_path
    	main_app.send(Auth::OmniAuth::Path.create_or_index_path(Auth.configuration.image_class))
    end

    ##/shopping/images/:id/edit
    def edit_image_path(image)
    	main_app.send(Auth::OmniAuth::Path.edit_path(Auth.configuration.image_class),image)
    end

    def create_multiple_images_path(options={})
        main_app.send("create_multiple_" + Auth.configuration.image_class.underscore.pluralize.gsub("\/","_")+ "_path",options)
    end

end