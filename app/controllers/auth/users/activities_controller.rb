class Auth::Users::ActivitiesController < ApplicationController

	respond_to :html,:json,:js

	##@used_in: jquery.calendario.js
	##@param[Hash] : params should have range key(which is itself a hash, and a user_id key which is a string.), {range: {"from" => date[format: ], "to" => date[format: ]}, user_id: String}
	##@return[Hash]: timestamp => activity_object hashified.
	def get_activities
		filt_test = permitted_params
		puts "the permitted_params are: #{filt_test}"
		Auth::Activity.get_in_range(filt_test)
	end

	private
	def permitted_params
		params.require(:user_id)
		params.require(:range).permit({:range => [:from, :to]})
	end

end
	