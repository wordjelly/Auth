class Auth::Users::ProfilesController < ApplicationController
	
	TCONDITIONS = {:only => [:get_user_id,:show]}

	include Auth::Concerns::DeviseConcern	
	include Auth::Concerns::TokenConcern


	before_action :do_before_request, only: [:get_user_id,:show]


	respond_to :html, :json, :js
		
	## this method needs token authentication, or for the user to be authenticated.
	def show
		@resource = User.find(params[:id])
	end

	## this route requires token authentication
	## and will return not authorized if token authentication fails.
	## will return the user id and the auth token and es if the authentication is successfull.
	## only purpose is a way to obtain the user id.
	## the user details can then be got through show.
	def get_user_id
		res = current_signed_in_resource
		puts "self m client is: #{self.m_client}"
		res.m_client = self.m_client
		respond_with current_signed_in_resource do |format|
			format.json {render json: current_signed_in_resource.as_json({:show_id => true})}
		end
	end

	##@used_in: email check if already exists. 
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
