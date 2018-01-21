class Auth::SearchController < ApplicationController
		

	CONDITIONS_FOR_TOKEN_AUTH = [:authenticated_user_search]

	TCONDITIONS = {:only => CONDITIONS_FOR_TOKEN_AUTH}

	include Auth::Concerns::DeviseConcern	
	include Auth::Concerns::TokenConcern

	before_action :do_before_request, TCONDITIONS
	
			
	## the intention of this action is :
	## to search all records as admin.
	## to search a user's own records if you are user.
	## to search all public records

	## so if the user is an admin, then no resource_id is provided to the search.(basically all records are searched)
	## if he's not an admin, then the lookup_resource user's id is provided.
	
	## this action assumes that the user is signed_in, will return not authenticated otherwise.
	def authenticated_user_search	
		
		
		query = permitted_params[:query]
		query[:resource_id] = lookup_resource.id.to_s if !current_signed_in_resource.is_admin?
		
		@search_response = Auth::Search::Main.search(permitted_params[:query])
		respond_with @search_response
	end



	def permitted_params
		params.permit({query: [:query_string, :size]})
	end


end
