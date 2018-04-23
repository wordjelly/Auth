class Auth::Workflow::Location

	include Auth::Concerns::WorkflowConcern

	include Mongoid::Geospatial


	embeds_many :tlocations, :class_name => Auth.configuration.tlocation_class

	field :location_categories, type: Array


	field :location, type: Point


	## @param[Hash] coordinates : a hash of the type :lat, :lng , which has the latitude and longitude near which you want to find the requirement categories. 
	## @param[Integer] within_radius : a radius from the coordinates, within which to search for locations.
	## @param[Array] requirement_categories : array of strings, which represent the requirement categories that are to be searched for.
	## @param[Array] time_range : start and end time within which to search for slots for the given requirements
	## @param[Float] average_transit_speed_in_kmph : 
	## @example : suppose we want to search if a scooter(req category 1) and rider(req category 2) is free, within 30 km of a certain location anytime between 9 am and 10 am. This query attempts to solve the problem.
	## @return
	def self.find_nearest_free_requirement_categories(coordinates,within_radius,entity_categories,time_range,average_transit_speed_in_kmph)

		point = Mongoid::Geospatial::Point.new(coordinates[:lng],coordinates[:lat])
		
		response = Auth.configuration.location_class.constantize.collection.aggregate([
				{
					"$geoNear" => {
						"near" => {
							"type" => "Point",
							"coordinates" => [coordinates[:lng],coordinates[:lat]]
						},
						"maxDistance" => 100,
						"distanceField" => "dist_calculated",
						"spherical" => true,
						"query" => {
							"$and" => [
								"tlocations" => {
									"$elemMatch" => {
											"booked" => false,
				 	    					"entity_category" => "1a",
				 	    					"start_time" => {
				 	    						"$gte" => time_range[0],
				 	    						"$lte" => time_range[1]
				 	    					}	
									}
								},
								"tlocations" => {
									"$elemMatch" => {
											"booked" => false,
				 	    					"entity_category" => "1",
				 	    					"start_time" => {
				 	    						"$gte" => time_range[0],
				 	    						"$lte" => time_range[1]
				 	    					}	
									}
								}
							]
						}
					}
				}
			])

		## here we want to further unwind,
		## then project a new field, that matches the tlocation duration to the approx time required to cover this distance.
		## then filter, out those which are more than that.
		## this will give us people free for that much time.
		## then we have to check the intersection of the time.
	
 	    ## okay now we have to add the location query.

 	    #puts response.count
 	    response.each do |res|
 	    	puts JSON.pretty_generate(res)
 	    end
 	   	## now we want to aggregate and project as per the distance and if the duration is equal to the 

	end
	

	def self.agg

		## basically we want to sum up the durations of the free slots.
		## these are present inside the tlocations.
		## so how to do this
		response = Auth.configuration.location_class.constantize.collection.aggregate([
			{
				"$addFields" =>
				{ 
					"test_field" => {
						"$reduce" => {
							"input" => "$tlocations",
							"initialValue" => {
								"free_duration" => 0,
								"last_value" => 0
							},
							"in" => {
								"free_duration" => {
									## here we have to apply the condition.
									## that if it is 
									"$cond" => {
										"if" => {
											"$eq" => ["$$value.last_value",0]
										},
										"then" => {
											"$sum" => [100,"$$value.free_duration"]
											
										},
										"else" => {"$sum" => [1,"$$value.free_duration"]
										}
									}
								},
								"last_value" => 0
							}
		 				}
	 				}
 				}

			},
 			"$project" => {
 				"test_field" => 1
 			}
		])

		response.each do |res|
			puts res.to_s
		end

	end
	
=begin
create a geoindex by doing the following command in the mongodb shell
db.my_collection_name.createIndex({location:"2dsphere"});
=end
	
end