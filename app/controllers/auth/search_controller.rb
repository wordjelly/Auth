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

	## rendering logic : 
	## @js erb -> renders html erb -> there each result class is detected and the requisite "_search.html.erb" partial is found for that class and rendered.
	## @json => authenticated_user_search.json is rendered.
	## @html => currently does not support html request.
	def authenticated_user_search	
		
		## m client will be available at this stage.
		## the problem is that it is hard to pass it forward to the mongoid elasticsearch object.
		## because while initializing the user it will have to first be set on the user.
		## is there any other way to achieve this?
		query = permitted_params[:query]
		query[:resource_id] = lookup_resource.id.to_s if !current_signed_in_resource.is_admin?
		
		@search_results = Auth::Search::Main.search(query)
		
		puts "these are the search results."
		puts @search_results.to_s

		#dummy_product = Auth.configuration.product_class.constantize.new
		#dummy_product.name = "test product"
		#dummy_product.price = 100.20
		#@search_results = [dummy_product,dummy_product]
		@search_results.each do |res|
			if res.respond_to? :m_client
				res.m_client = self.m_client
			end
		end
		respond_with @search_results
	end



	def permitted_params
		params.permit({query: [:query_string, :size]})
	end


end
