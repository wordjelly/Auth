module Auth::Shopping::Personalities::PersonalitiesHelper

	## get /new
	def new_personality_path
      main_app.send(Auth::OmniAuth::Path.new_path(Auth.configuration.personality_class))
    end

    ## (PUT/PATCH/GET) - individual personality
    def personality_path(personality)
    	
    	main_app.send(Auth::OmniAuth::Path.show_or_update_or_delete_path(Auth.configuration.personality_class),personality)
    end

	
	##/personalities (GET - all personalities /CREATE - individual personality) 
	def personalities_path
    	main_app.send(Auth::OmniAuth::Path.create_or_index_path(Auth.configuration.personality_class))
    end

    ##/shopping/personalities/:id/edit
    def edit_personality_path(personality)
    	main_app.send(Auth::OmniAuth::Path.edit_path(Auth.configuration.personality_class),personality)
    end

   
end