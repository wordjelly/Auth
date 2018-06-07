class Auth::ProfilesController < Auth::ApplicationController
		
	CONDITIONS_FOR_TOKEN_AUTH = [:get_user_id,:show,:update,:set_proxy_resource]

	TCONDITIONS = {:only => CONDITIONS_FOR_TOKEN_AUTH}

	include Auth::Concerns::DeviseConcern	
	include Auth::Concerns::TokenConcern

	before_action :do_before_request, TCONDITIONS
	before_action :initialize_vars, TCONDITIONS
	before_action :is_admin_user, :only => [:set_proxy_user]
	
	def initialize_vars
		puts "---------------------------------------------------"
		@resource_params = {}
		@profile_resource = nil
		@all_params = permitted_params.deep_symbolize_keys
		
		
	  	if collection = @all_params[:resource]
	  		
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
	## so what if i sign in as one user,and send in the id of another user?, no because we use the find_resource method, which also considers the current_signed_in_Resource.
	def show
		@profile_resource
	end


	## this method needs the token authentication and an :id, hence the profile resource is updated.
	## expected params hash:
	##{:resource => "users", :user => {:admin,:request_send_reset_password_link}, :id}
	def update
		check_for_update(@profile_resource)
		
		if @resource_params[:admin]
			@profile_resource.admin = @resource_params[:admin]
		end

		if @resource_params[:created_by_admin]
			@profile_resource.created_by_admin = @resource_params[:created_by_admin]
		end

		@profile_resource.m_client = self.m_client
		
		
		respond_to do |format|
  		  if @profile_resource.save
  		  	  flash[:notice] = "Success"
	  		  format.json {head :no_content}
	  		  format.html {redirect_to profile_path({:id => @profile_resource.id.to_s, :resource => @profile_resource.class.name.pluralize.downcase.to_s})}
  		  else
  		  	  flash[:notice] = "Failed"
  		  	  format.json {render :json => @profile_resource.errors, :status => :unprocessable_entity}
  		  	  format.html {redirect_to profile_path({:id => @profile_resource.id.to_s, :resource => @profile_resource.class.name.pluralize.downcase.to_s})}
  		  end
  		end
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

	## THIS IS HOW YOU SET A PROXY USER AS AN ADMIN.
	## this method takes an id.
	## it also needs current signed in user to be an admin.
	## it basically takes the @profile_resource
	## then it shoves it into the session as  proxy_resource_id and proxy_resource_class
	## then it returns the profile_resource.
	## it responds only to js
	## it is meant to be used only for setting the proxied user by an admin in the web application.
	## expect the params to contain 
	## params[:proxy_resource_id] and params[:proxy_resource_class]
	def set_proxy_resource
		not_found("that user doesn't exist") unless @profile_resource
		session[:proxy_resource_id] = @profile_resource.id.to_s
		session[:proxy_resource_class] = @profile_resource.class.name.to_s
		#puts "the session variables set are as follows:"
		#puts session[:proxy_resource_id]
		#puts session[:proxy_resource_class]
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
			## this basically enables passing in something like;
			## to help us to set a user as admin.
			## provided that the current_signed_in_Resource is an admin.
			## "user" => {:admin => true}
			## we also want to allow to set :created_by_admin => true, 
			## so that is also enabled, if the user is an admin,
	  		Auth.configuration.auth_resources.keys.each do |model|
	  			if current_signed_in_resource && current_signed_in_resource.is_admin?
	  				filters << {model.downcase.to_sym => [:admin,:created_by_admin]}
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
