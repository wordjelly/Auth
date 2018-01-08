class Auth::RegistrationsController < Devise::RegistrationsController
	include Auth::Concerns::TokenConcern
	before_action :check_recaptcha, only: [:create, :update]
	def self.token_authentication_conditions
		{:only => [:edit,:update,:destroy]}
	end

	def create
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

end
