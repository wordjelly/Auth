module Auth::Work::Bullets::BulletsHelper
    ## get /new
=begin
	def new_bullet_path
      main_app.send(Auth::OmniAuth::Path.new_path(Auth.configuration.bullet_class))
    end

    ## (PUT/PATCH/GET) - individual bullet
    def bullet_path(bullet)
    	
    	main_app.send(Auth::OmniAuth::Path.show_or_update_or_delete_path(Auth.configuration.bullet_class),bullet)
    end

	
	##/bullets (GET - all bullets /CREATE - individual bullet) 
	def bullets_path
    	main_app.send(Auth::OmniAuth::Path.create_or_index_path(Auth.configuration.bullet_class))
    end

    ##/shopping/bullets/:id/edit
    def edit_bullet_path(bullet)
    	main_app.send(Auth::OmniAuth::Path.edit_path(Auth.configuration.bullet_class),bullet)
    end
=end
end