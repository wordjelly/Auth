class Auth::RegistrationsController < Devise::RegistrationsController
	
	TCONDITIONS = {:only => [:update,:destroy]}

	include Auth::Concerns::TokenConcern

	#before_action :check_recaptcha, only: [:create, :update]


	def create
		puts "CAME TO CREATE."
		check_recaptcha
		build_resource(sign_up_params)
		resource.m_client = self.m_client
	 	resource.set_client_authentication
	    resource.save
	    yield resource if block_given?
	    if resource.persisted?
	      if resource.active_for_authentication?
	        set_flash_message! :notice, :signed_up
	        sign_up(resource_name, resource)
	        respond_with resource, location: after_sign_up_path_for(resource)
	      else
	        set_flash_message! :notice, :"signed_up_but_#{resource.inactive_message}"
	        expire_data_after_sign_in!
	        respond_with resource, location: after_inactive_sign_up_path_for(resource)
	      end
	    else
	      clean_up_passwords resource
	      set_minimum_password_length
	      respond_with resource
	    end

	end


	


	def update
		check_recaptcha
		self.resource = resource_class.to_adapter.get!(send(:"current_#{resource_name}").to_key)
	    prev_unconfirmed_email = resource.unconfirmed_email if resource.respond_to?(:unconfirmed_email)
	    ## added these two lines
	    resource.m_client = self.m_client
	 	resource.set_client_authentication
	 	## end.
	 	
	    resource_updated = update_resource(resource, account_update_params)
	    
	    yield resource if block_given?
	    if resource_updated
	      if is_flashing_format?
	        flash_key = update_needs_confirmation?(resource, prev_unconfirmed_email) ?
	          :update_needs_confirmation : :updated
	        set_flash_message :notice, flash_key
	      end
	      sign_in resource_name, resource, bypass: true
	      respond_with resource, location: after_update_path_for(resource)
	    else
	      clean_up_passwords resource
	      respond_with resource
	    end
	end

	##had to do this, cuz after update, the authentication token changes, and that needs to be communicated back to the client, or they will never be able to update or access the resource again.
    def respond_with(*args)
      if is_json_request?
        if args[0] && args[0].respond_to?(:authentication_token)
          render :json => args[0] 
        else
          super(*args)
        end
      else
        super(*args)
      end
    end

    def respond_with_navigational(*args, &block)
      if is_json_request?
        respond_with(*args)
      else
        respond_with(*args) do |format|
          format.any(*navigational_formats, &block)
        end
      end
    end

    
    ## only required in case of registrations controller, for the update action, and destroy actions, wherein we need to make sure that the resource is authenticated before doing anything.
    ## have overridden the devise method here.
    ## it has nothing to do with the simple_token_authentication being done in other controllers. 
    ## this was just done here because we cannot add simple_token_authentication to a devise controller.
    def authenticate_scope!
      
     
      do_before_request  

    end
	
end

