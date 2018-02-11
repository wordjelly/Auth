module Auth
	module Search
		module Main
			## this def, returns a hash with the structure for the basic ngram query.
			## the query_string is left blank, and you should merge this in through any def that wants to perform an ngram query.
			## @return[Hash]
			def self.base_ngram_query
				{
					body: {
						query: {
							filtered: 
							{
								query: {
									match: {
										_all: {
											query: "",
											operator: "and"
										}
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
			end

			## @param[Hash] : This is expected to contain the following:
			## @query_string : the query supplied by the user
			## @resource_id : a resource_id with which to filter search results, if its not provided, no filter is used on the search results
			## @size : if not provided a default size of 20 is used
			## this def will use the #base_ngram_query hash and merge in a filter for the resource_id.
			
			## 'Public' Resources
			##  if the public field is present, don't add any resource_id filter.
			##  if the public field is not present, then add the resource_id filter if the resource_id is provided.

			
			## @return[Array] response: an array of mongoid search result objects. 
			def self.search(args)	
				args = args.deep_symbolize_keys
				return [] unless args[:query_string]
				query = base_ngram_query
				
				## set all the required values.
				query[:size] = args[:size] || 20
	
				query[:body][:query][:filtered][:query][:match][:_all][:query] = args[:query_string]
				if args[:resource_id]
					query[:body][:query][:filtered][:filter] = {
							
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

				#puts JSON.pretty_generate(query)
				Mongoid::Elasticsearch.search(query,{:wrapper => :load}).results
			end
		end
	end
end