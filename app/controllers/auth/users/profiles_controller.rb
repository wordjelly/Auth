class Auth::Users::ProfilesController < ApplicationController
	respond_to :html, :json, :js
	
	def show
		
	end

	##@used_in: jquery.calendario.js
	##@param[Array]: Integer timestamp from, integer timestamp to
	##@return[Hash]: timestamp => activity_object hashified.
	def get_activities
		
	end

	##@used_in: email check if already exists. 
	def credential_exists
		filt = permitted_params
		resource = get_model(filt["resource"])
		is_valid = false
		if resource
			conditions = (filt.keys - ["resource"]).map{|c|
				c = {c => filt[c]}
			}
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
