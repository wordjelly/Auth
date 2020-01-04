module Auth::Shopping::Places::PlacesHelper

	## get /new
	def new_place_path
      main_app.send(Auth::OmniAuth::Path.new_path(Auth.configuration.place_class))
    end

    ## (PUT/PATCH/GET) - individual place
    def place_path(place)
    	
    	main_app.send(Auth::OmniAuth::Path.show_or_update_or_delete_path(Auth.configuration.place_class),place)
    end

	
	##/places (GET - all places /CREATE - individual place) 
	def places_path
    	main_app.send(Auth::OmniAuth::Path.create_or_index_path(Auth.configuration.place_class))
    end

    ##/shopping/places/:id/edit
    def edit_place_path(place)
    	main_app.send(Auth::OmniAuth::Path.edit_path(Auth.configuration.place_class),place)
    end

   
end