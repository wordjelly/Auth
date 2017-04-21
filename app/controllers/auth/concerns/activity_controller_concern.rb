module Auth::Concerns::ActivityControllerConcern
	
	extend ActiveSupport::Concern

	included do 

		respond_to :html,:json,:js

	end

	##@used_in: jquery.calendario.js
	##@param[Hash] : params should have range key(which is itself a hash, and a user_id key which is a string.), {range: {"from" => date[format: ], "to" => date[format: ]}, user_id: String}
	##@return[Hash]: timestamp => activity_object hashified.
	def get_activities
		filt_test = permitted_params
		activities_hash = model.get_in_range(filt_test)
		respond_with activities_hash
	end

	
	

	##gives the model class from the underlying controller
	def model
		Object.const_get(controller_name.classify)
	end

	def permitted_params
		params.permit(:user_id, range: [:from, :to], only: [])
	end

end