class Auth::Workflow::Location

	#include Auth::Concerns::WorkflowConcern

	#include Mongoid::Geospatial

	include Mongoid::Document

	embeds_many :tlocations, :class_name => Auth.configuration.tlocation_class

	embeds_many :minutes, :class_name => Auth.configuration.minute_class

	field :day_id, type: Integer

	field :location_categories, type: Array

	## let us say it embeds many minutes.
	
	## and each minute embeds many entities.
	## and each entity has 

	## it has to be committed like :
	## {:type => "Point", :coordinates => [lng,lat]}
	field :geom, type: Array

	## also remember to make an index on it.
	## this may be the only reason why this is not working as expected.


	## @param[Hash] coordinates : a hash of the type :lat, :lng , which has the latitude and longitude near which you want to find the requirement categories. 
	## @param[Integer] within_radius : a radius from the coordinates, within which to search for locations. Should be specified in meters only.
	## @param[Array] requirement_categories : array of strings, which represent the requirement categories that are to be searched for.
	## @param[Array] time_range : start and end time within which to search for slots for the given requirements
	## @param[Float] average_transit_speed_in_mph : the speed at which the requirement is expected to cover the distance, specified in meters per hour. 
	## @example : suppose we want to search if a scooter(req category 1) and rider(req category 2) is free, within 30 km of a certain location anytime between 9 am and 10 am. This query attempts to solve the problem.
	## @return
	def self.find_nearest_free_requirement_categories(coordinates,within_radius,entity_categories,time_range,average_transit_speed_in_mph)

		agg_stages = [
			{
				"$geoNear" => {
					"near" => {
						"type" => "Point",
						"coordinates" => [coordinates[:lng],coordinates[:lat]]
					},
					"maxDistance" => within_radius,
					"spherical" => true,
					"distanceField" => "dist_calculated",
    				"includeLocs" => "dist_location",
    				"query" => {
    					"tlocations" => {
							"$elemMatch" => {
								"booked" => false,
	 	    					"entity_category" => entity_categories[0],
	 	    					"start_time" => {
	 	    						"$gte" => time_range[0],
	 	    						"$lte" => time_range[1]
	 	    					}
							}
						}	
    				}
				}
			},
			{
				"$addFields" => {
					"approx_duration" => {
						"$divide" => 
							[
								"$dist_calculated",
								average_transit_speed_in_mph
							]
					}
				}
			},
			{
				"$unwind" => "$tlocations"
			},
			## keep those documents where the category is one of which we need, and duration is > required duration.
			## use a reduce to add to an array the categories which we are interested in, if it is of the required duration.
			## and then 
			## there has to be another less complicated way to get these overlapping requirement free slots.
=begin
			{
				"$project" => {
					"altered_overlaps" => {
						"$reduce" => {
							"input" => "$tlocations.overlaps",
							"initialValue" => {
								"our_categories" => []
							},
							"in" => {
								"our_categories" => {
									"$cond" => {
										"if" => {
											"$and" => [
												{
													"$setIsSubset" => 
												}
											]
										}
									}
								}
							}

						}
					}	
				}
			}
=end
			## filter on the overlaps.
			## now we have only which overlap with the targets.
			## and then we need to know which of them overlap for atleast that long.
			## modify the overlaps, if the the overlap duration is 
		]

=begin
		entity_categories[1..-1].each do |category|


			agg_stages[4]["$match"]["$and"][0]["tlocations.overlaps"]["$all"] <<  
				{
					"$elemMatch" => {
						"overlap_duration" => {
							"$gte" => "$approx_duration"
						},
						"overlap_booked" => false,
						"overlap_category" => category
					}
    			}
		end
=end
		puts JSON.pretty_generate(agg_stages)

		response = Auth::Workflow::Location.collection.aggregate(agg_stages)

		
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

	def self.loc(speed=20,coordinates={:lat => 27.45, :lng => 58.22},within_radius=10000,categories=["1","2","3"],time_range=[0,100])

		aggregation_clause = 
		[
			{
				"$geoNear" => {
					"near" => {
						"type" => "Point",
						"coordinates" => [coordinates[:lng],coordinates[:lat]]
					},
					"maxDistance" => within_radius,
					"spherical" => true,
					"distanceField" => "dist_calculated",
					"includeLocs" => "dist_location",
					"query" => {
						"minutes.entities" => {
							"$all" => [

							]
						}
					}
				}
			},
			{
				"$addFields" => {
					"approx_duration" => {
						"$divide" => 
							[
								"$dist_calculated",
								speed
							]
					}
				}
			},
			{
				"$unwind" => "$minutes"
			},
			{
				"$match" => {
					"minutes.entities" => {
						"$all" => [

						]
					}	
				}
			},
			{
				"$addFields" => {
					"has_duration" => {
						"$subtract" => 
						[
							"$minutes.minimum_entity_duration",
							"$approx_duration"
						]
					}
				}
			},
			{
				"$match" => {
					"has_duration" => {
						"$gte" => 0
					}
				}
			},
			{
				"$limit" => 1
			}
		]

		categories.each do |category|
			aggregation_clause[0]["$geoNear"]["query"]["minutes.entities"]["$all"] << 
			{
				"$elemMatch" => {
					"category" => category,
					"booked" => false
				}
			}
		end

		categories.each do |category|
			aggregation_clause[3]["$match"]["minutes.entities"]["$all"] << 
			{
				"$elemMatch" => {
					"category" => category,
					"booked" => false
				}
			}
		end

		Auth.configuration.location_class.constantize.collection.aggregate(aggregation_clause)

	end
	
=begin
create a geoindex by doing the following command in the mongodb shell
db.my_collection_name.createIndex({location:"2dsphere"});
=end
	
end