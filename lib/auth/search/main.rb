module Auth
	module Search
		module Main

			## this def, returns a hash with the structure for the basic ngram query.
			## the query_string is left blank, and you should merge this in through any def that wants to perform an ngram query.
			## param[Symbol] search_on_field : the field on which we are going to do the n_Gram query. Most of the times this should default to _all_fields
			## @return[Hash]
			def self.es_six_base_ngram_query(search_on_field)
				
				search_on_field ||= :all_fields

				qc = {
					body: {
						query: {
							bool: {
								must: {
									match: {
										
									}
								},
								filter: {
									match_all:{

									}
								}
							}
						}
					}
				}

				qc[:body][:query][:bool][:must][:match][search_on_field] = {
						query: "",
						operator: "and"
				}	

				qc

			end


			## searches all indices, for the search string.
			## @param[Hash] : This is expected to contain the following:
			## @query_string : the query supplied by the user
			## @resource_id : a resource_id with which to filter search results, if its not provided, no filter is used on the search results
			## @size : if not provided a default size of 20 is used
			## this def will use the #base_ngram_query hash and merge in a filter for the resource_id.
			## 'Public' Resources
			##  if the public field is present, don't add any resource_id filter.
			##  if the public field is not present, then add the resource_id filter if the resource_id is provided.
			## @return[Hash] : returns a query clause(hash) 
			def self.es_six_finalize_search_query_clause(args)

				search_on_field = args[:search_field] || :_all_fields
				
				args = args.deep_symbolize_keys
				
				return [] unless args[:query_string]
				
				query = es_six_base_ngram_query(search_on_field)
				
				query[:size] = args[:size] || 20
				
				query[:body][:query][:bool][:must][:match][search_on_field][:query] = args[:query_string]

				
				if args[:resource_id]
					query[:body][:query][:bool][:filter] = {
							
								bool: {
									should: [
										{
											bool: {
												must: [
													{
														term: {
															public: "no"
														}
													},
													{
														term: {
															resource_id: args[:resource_id]
														}
													}
												]
											}
										},
										{
											term: {
												public: "yes"
											}
										}
									]
								}
							
						}
				else
					## if a resource id is not provided then
					## it means that the resource is admin,
					## and they should be able to access and see
					## any resource
					## so in that case we leave the query
					## as is.
				end

				query

			end


			## delegates the building of the query to finalize_search_query_clause.
			## @return[Array] response: an array of mongoid search result objects. 
			def self.search(args)	
				query = es_six_finalize_search_query_clause(args)
				puts "query finalized as:"
				puts JSON.pretty_generate(query)
				Mongoid::Elasticsearch.search(query,{:wrapper => :load}).results
			end
		end
	end
end