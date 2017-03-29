class Auth::Users::ProfilesController < ApplicationController
	respond_to :html, :json, :js
	
	def show
		@resource = User.find(params[:id])
	end

	##@used_in: jquery.calendario.js
	##@param[Hash] : params should have range key(which is itself a hash, and a user_id key which is a string.), {range: {"from" => date[format: ], "to" => date[format: ]}, user_id: String}
	##@return[Hash]: timestamp => activity_object hashified.
	def get_activities
		filt_test = permitted_params
		puts "the permitted_params are: #{filt_test}"
		Auth::Activity.get_in_range(filt_test)
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
		elsif action_name.to_s == "get_activities"
			params.require(:user_id)
			params.require(:range).permit({:range => [:from, :to]})
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
