module Auth::Concerns::ActivityConcern

	extend ActiveSupport::Concern

	included do 

		include Mongoid::Document
		include Mongoid::Timestamps

		field :user_id, 			type: BSON::ObjectId
		field :image_url, 			type: String

	end

	module ClassMethods
		##db.auth_activities.aggregate( { $project: { month: {$month: "$created_at"} } },{ $group: { _id: {month: "$month"}, count: {$sum: 1} } } )
		def test_agg
			Object.const_get(name).collection.aggregate([
					{
						"$match" => Object.const_get(name).where(:created_at.gte => Time.now.to_i - 100.days, :created_at.lte => Time.now.to_i).selector
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
		end

		##@param[Hash] {"range" : {"from" : unix_epoch_as_string, "to" => unix_epoch_as_string}, "user_id": string, "only": [array_of_attributes_required]}
		##"range" => optional,if nil or empty, "from" and "to" will be automatically assigned to beginning_of_current_month and current_time respectively
		##"user_id" => required, will return empty hash if absent.
		##"only" => optional, will default to all attributes of the activity model.
		##@return[Hash]: timestamp => activity_object hashified.
		def get_in_range(params)
			
			## return empty hash if there is no user_id
			return {} unless params[:user_id]
			

			## merge defaults
			defaults = {"range" => {"from" => Time.now.beginning_of_month.to_i, "to" => Time.now.to_i}, "only" => Object.const_get(name).fields.keys}
			params = defaults.deep_merge(params)
			

			##default from and to assigned here.
			from = params["range"]["from"].to_i
			to = params["range"]["to"].to_i
			if from >= to
				from = Time.now.beginning_of_month.to_i
				to = Time.now.to_i
			end



			##defaults for only.
			##if it is empty or nil, then it becomes all attributes
			##otherwise it becomes the intersect of all attributes and the ones specified in the only
			##created_at had to be added here, because otherwise it throws an error saying missing_attribute in the only. I think this has something to do with the fact that it is used in the query, so it will be included in the result.
			only = ((Object.const_get(name).fields.keys & params["only"]) + ["created_at"])

			##make the mongoid range call here.
			activities = Object.const_get(name).where(:created_at.gte => from, :created_at.lte => to, :user_id => params["user_id"]).only(only)

			activities_hash = Hash[activities.entries.map{|c| c.created_at.to_i}.zip(activities.entries.map{|c| c.as_json})]
			puts JSON.pretty_generate(activities_hash)
			return activities_hash
		
		end
		
	end



end