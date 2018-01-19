class Auth::ProfilesController < Auth::ApplicationController
		
	CONDITIONS_FOR_TOKEN_AUTH = [:get_user_id,:show,:update,:set_proxy_user]

	TCONDITIONS = {:only => CONDITIONS_FOR_TOKEN_AUTH}

	include Auth::Concerns::DeviseConcern	
	include Auth::Concerns::TokenConcern

	before_action :do_before_request, TCONDITIONS
	before_action :initialize_vars, TCONDITIONS
	before_action :is_admin_user, :only => [:set_proxy_user]
	
	
	def initialize_vars
		@resource_params = {}
		@profile_resource = nil
		@all_params = permitted_params.deep_symbolize_keys
	  	if collection = @all_params[:resource]
	  		##check that the resource exists in the auth_configuration
	  		if Auth.configuration.auth_resources[collection.singularize.capitalize]
	  			@resource_class = collection.singularize.capitalize.constantize
	  			@resource_symbol = collection.singularize.to_sym
	  			@resource_params = @all_params.fetch(@resource_symbol,{})
	  			@profile_resource = @all_params[:id] ? @resource_class.find_resource(@all_params[:id],current_signed_in_resource) : @resource_class.new(@resource_params)
	  		end
	  	end	    
	end


	## this method needs token authentication, or for the user to be authenticated.
	## this method also needs an :id, hence the profile_resource is returned.
	def show
		@profile_resource
	end


	## this method needs the token authentication and an :id, hence the profile resource is updated.
	def update
		check_for_update(@profile_resource)
		
		@profile_resource.admin = @resource_params[:admin]
		
		@profile_resource.m_client = self.m_client
		
		@profile_resource.save
		
		respond_with @profile_resource
	end

	## here the idea is to just return the current_signed_in_resource's id.
	## it doesn't have anything to do with the profiel
	## since no id is sent into the params, so profile_resource will never be found.
	def get_user_id
		res = current_signed_in_resource
		res.m_client = self.m_client
		respond_with current_signed_in_resource do |format|
			format.json {render json: current_signed_in_resource.as_json({:show_id => true})}
		end
	end

	## this method takes an id.
	## it also needs current signed in user to be an admin.
	## it basically takes the @profile_resource
	## then it shoves it into the session as  proxy_resource_id and proxy_resource_class
	## then it returns the profile_resource.
	## it responds only to js
	## it is meant to be used only for setting the proxied user by an admin in the web application.
	def set_proxy_user
		not_found("that user doesn't exist") unless @profile_resource
		session[:proxy_resource_id] = @profile_resource.id.to_s
		session[:proxy_resource_class] = @profile_resource.id.to_s
		## there is only a js erb set_proxy_user file in the profiles_views
		## so it will only respond to js erb.
		## it looks for a div called "proxy_user"
		## and then it populates that div with details of the 
		## proxy user.
	end

	##@used_in: email check if already exists. 
	## this method is only usable through web.
	## not available currently for api use.
	def credential_exists
		filt = permitted_params
		resource = get_model(filt["resource"])
		is_valid = false
		if resource
			conditions = resource.credential_exists(filt)
			is_valid = (resource.or(*conditions).count == 0)
		end
		respond_to do |format|
		  format.json { render json: {"is_valid" => is_valid} }
		end
	end

	private
	def permitted_params
		if action_name.to_s == "credential_exists"
			params.require(:credential).permit(Devise.authentication_keys + [:resource])	
		else
			filters = []
	  		Auth.configuration.auth_resources.keys.each do |model|
	  			if current_signed_in_resource && current_signed_in_resource.is_admin?
	  				filters << {model.downcase.to_sym => [:admin]}
	  			end
	  		end
	  		filters << [:resource,:api_key,:current_app_id,:id]
	  		params.permit(filters)
		end
	end

	##@used_in : profiles_controller
 	##@param[String] resource name : it is expected to end with the model name, preceeded by a slash. eg: authenticate/user
 	##@return[Object] : returns the the klass of the model. eg.: User
 	def get_model(resource_name)
 		model_name = nil
 		resource_name.scan(/\/(?<model_name>[a-z]+)$/) do |jj|
 			ll = Regexp.last_match
 			model_name = ll[:model_name]
 		end
 		return unless model_name
 		return Object.const_get(model_name.singularize.capitalize)
 	end
end
