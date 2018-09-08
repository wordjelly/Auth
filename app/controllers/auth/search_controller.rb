class Auth::SearchController < ApplicationController
		

	CONDITIONS_FOR_TOKEN_AUTH = [:authenticated_user_search]

	TCONDITIONS = {:only => CONDITIONS_FOR_TOKEN_AUTH}
	LAST_FALLBACK = :none

	include Auth::Concerns::DeviseConcern	
	include Auth::Concerns::TokenConcern

	before_action :do_before_request, TCONDITIONS

	## only option is to set no fallback
	## so that it will just go through.

			
	## permitted_params[:query] is expected to be a hash, which can provide the following arguments
	## :query_string => a string for the query
	## :search_on_field => the field name on which the search can be performed, will default to the 'tags' field.
	## :size => the number of results to return, will default to 5.
	## @js erb -> renders html erb -> there each result class is detected and the requisite "_search.html.erb" partial is found for that class and rendered.
	## @json => authenticated_user_search.json is rendered.
	## @html => currently does not support html request.
	def authenticated_user_search	

		## remaining implementation is that a default as_json public has to be set to "no" for everything, and overriding it will be the job of the implementer to set it to "yes"
		## that way a filter is maintained.

		query = permitted_params[:query]

		if current_signed_in_resource
			if current_signed_in_resource.is_admin?
				query[:resource_is_admin] = true
			else
				query[:resource_id] = lookup_resource.id.to_s
			end
		end
		
		@search_results = Auth::Search::Main.search(query)
		
		@search_results.each do |res|
			if res.respond_to? :m_client
				res.m_client = self.m_client
			end
		end

		puts "these are the search results."
		@search_results.each do |result|
			puts result.to_s	
		end

		


		respond_with @search_results
	end



	def permitted_params
		params.permit({query: [:query_string, :size]})
	end


end
