module Auth::Concerns::ActivityConcern

	extend ActiveSupport::Concern

	included do 

		include Mongoid::Document
		include Mongoid::Timestamps

		field :user_id, 			type: BSON::ObjectId
		field :image_url, 			type: String

	end

	module ClassMethods

		##the default "from" is the beginning of the current month, and the default "to" is the current time.
		##@used_in : last_n_months, get_in_range
		##@param[Hash]  query: the "from","to" provided in the query if at all, otherwise nil, assumed that query has two keys : "from", "to", under a key called "range"
		##@param[Integer] default_from : the default_from for the particular function that is firing this query, it is an epoch
		##@param[Integer] default_to : the default_to for the particular function that is firing this query, it is an epoch
		##@return[Hash] : default values for "from", "to"
		def activities_from_to(query,default_from,default_to)
			defaults = {"range" => {"from" => default_from, "to" => default_to}}
			query = defaults.deep_merge(query)
			##default from and to assigned here.
			from = query["range"]["from"].to_i
			to = query["range"]["to"].to_i
			if from >= to
				query["range"]["from"] = default_from
				query["range"]["to"] = default_to
			end
			return query
		end


		##defaults for only.
		##if it is empty or nil, then it becomes all attributes
		##otherwise it becomes the intersect of all attributes and the ones specified in the only
		##created_at had to be added here, because otherwise it throws an error saying missing_attribute in the only. I think this has something to do with the fact that it is used in the query, so it will be included in the result.
		##@used_in: get_in_range
		##@param[query] : the provided query, expected to be of the structure: 
		##{"only" => [array],,,other key value pairs}
		##@return[Hash] query : returns the query with the default values for the fields to be returned
		def activities_fields(query)
			defaults = {"only" => Object.const_get(name).fields.keys}
			query = defaults.deep_merge(query)
			only = ((Object.const_get(name).fields.keys & query["only"]) + ["created_at"])
			query["only"] = only
			return query
		end

		##@param[Hash] query_params: {"range" : {"from" : unix_epoch_as_string, "to" => unix_epoch_as_string}, "user_id": string, "only": [array_of_attributes_required]}
		##"range" => optional,if nil or empty, "from" and "to" will be automatically assigned to beginning_of_current_month and current_time respectively
		##"user_id" => required, will return empty hash if absent.
		##@return[Hash] agg_hash: the aggregation hash
		def last_n_months(query_params)
			return {} unless query_params[:user_id]
			query_params = Object.const_get(name).activities_from_to(query_params, Time.now.to_i = 12.months, Time.now.to_i)
			
			agg_hash = Object.const_get(name).collection.aggregate([
					{
						"$match" => Object.const_get(name).where(:created_at.gte => query_params["range"]["from"], :created_at.lte => query_params["range"]["to"], :user_id => query_params[:user_id]).selector
					},
					{
						"$project" => {
							month: {
								"$month" => "$created_at"
							}
						}
					},
					{
						"$group" => {
							"_id" => {
								month: "$month"
							},
							count: {
								"$sum" => 1
							}
						}
					}]
				)

			return agg_hash

		end

		##@param[Hash] query_params: {"range" : {"from" : unix_epoch_as_string, "to" => unix_epoch_as_string}, "user_id": string, "only": [array_of_attributes_required]}
		##"range" => optional,if nil or empty, "from" and "to" will be automatically assigned to beginning_of_current_month and current_time respectively
		##"user_id" => required, will return empty hash if absent.
		##"only" => optional, will default to all attributes of the activity model.
		##@return[Hash]: timestamp => activity_object hashified.
		def get_in_range(query_params)
			
			## return empty hash if there is no user_id
			return {} unless query_params[:user_id]
			query_params = Object.const_get(name).activities_from_to(query_params, Time.now.beginning_of_month.to_i, Time.now.to_i)
			query_params = Object.const_get(name).activities_fields(query_params)

			##make the mongoid range call here.
			activities = Object.const_get(name).where(:created_at.gte => query_params["range"]["from"], :created_at.lte => query_params["range"]["to"], :user_id => query_params["user_id"]).only(query_params["only"])

			activities_hash = Hash[activities.entries.map{|c| c.created_at.to_i}.zip(activities.entries.map{|c| c.as_json})]

			puts JSON.pretty_generate(activities_hash)
			
			return activities_hash
		
		end
		
	end



end