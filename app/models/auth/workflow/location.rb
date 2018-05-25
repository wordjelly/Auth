class Auth::Workflow::Location

	#include Auth::Concerns::WorkflowConcern

	#include Mongoid::Geospatial

	include Mongoid::Document

	embeds_many :tlocations, :class_name => Auth.configuration.tlocation_class

	embeds_many :minutes, :class_name => Auth.configuration.minute_class

	field :location_categories, type: Array

	## let us say it embeds many minutes.
	
	## and each minute embeds many entities.
	## and each entity has 

	## it has to be committed like :
	## {:type => "Point", :coordinates => [lng,lat]}
	field :geom, type: Array


=begin
	logic for range determination
	initially we have 
=end	
			
	## its basically superfast.
	## so what we need to do is 
	def self.bench
		a = []
		10000000.times do |n|
			a << n
		end
		s = []
		10000.times do |k|
			s << k
		end
		Benchmark.bm do |x|
		  
		  x.report "Array#bsearch" do
		    s.size.times do |l|
		    	a.bsearch{|y| y >= l }
			end
		  end
		  
		end

	end

=begin
FOR ALL THE QUERY METHODS, THE STRUCTURE OF THE INCOMING ARRAY IS AS FOLLOWS:
[
	{
		"location_id" : String,
		"location_coordinates" : Array[lat,lng],
		"location_categories" : Array[String],
		"within_radius" : Float(meters),
		"speed" : Float(meters/s),
		"start_time_range_beginning" => Integer,
		"start_time_range_end" => Integer,
		"duration" => Float(seconds),
		"categories" : 
		[
			{
				"category" : String,
				"arrives_at_location_id_categories" => Array[String],
				"transport_capacity" => Float,
				"capacity" => Float
				/// either transport_capacity or capacity can be there, both cannot be defined at the same time.
			}
		],
		"consumables" : 
		[
			consumable_object_1,
			consumable_object_2
		]
	}
]


=end
			
	#################################################################
	##
	##
	## AGGREGATION CLAUSES : ONE METHOD FOR EACH CLAUSE. 
	##
	##
	#################################################################

	## will check if the location ids or categories are to be returned.
	## if neither ids nor categories are specified, then will return nothing.
	def self.filter_by_location_ids_or_categories?(query_array)
		
		ids = query_array.map{|c| c = c["location_id"]}
		
		categories = query_array.map{|c| c = c["location_categories"]}
		
		ids.compact!
		
		categories.compact!

		raise "both location ids and categories provided" if (ids.size > 0 && categories.size > 0)

		return "ids" if ids.size > 0
		return "categories" if categories.size > 0
		return nil

	end

	def self.add_geo_filter(aggregation_clause,query_array,coordinates,max_distance,ids_or_categories="ids")

		aggregation_clause << {
			"$geoNear" => {
				"near" => {
					"type" => "Point",
					"coordinates" => [coordinates[:lng],coordinates[:lat]]
				},
				"maxDistance" => max_distance,
				"spherical" => true,
				"distanceField" => "dist_calculated",
				"includeLocs" => "dist_location",
				"query" => {
					
				}
			}
		}

		if ids_or_categories
			if ids_or_categories == "ids"
				aggregation_clause.last["$geoNear"]["query"] = {
					"_id" => {
						"$in" => query_array.map{|c| c = c["location_id"]}
					}
				}
			else
				aggregation_clause.last["$geoNear"]["query"] = {
					"location_categories" => {
						"$in" => query_array.map{|c| c = c["location_categories"]}.flatten
					}
				}
			end
		end

		aggregation_clause

	end


	def self.add_approx_duration_field(aggregation_clause,speed)
		aggregation_clause << {
			"$addFields" => {
				"approx_duration" => {
					"$divide" => 
						[
							"$dist_calculated",
							speed
						]
				}
			}
		}
		aggregation_clause
	end

	## the next step will depend on whether this is a travel to type of query or what type of query?
	## if it is a simple find_entity_near_point.

	## @param[Array] query_array
	## @param[Array] aggregation_clause 
	def self.add_location_id_filter(aggregation_clause,query_array)
		aggregation_clause << {
			"$match" => {
				"_id" => {
					"$in" => query_array.map{|c| c = c["location_id"]}
					}
			}
		}
		aggregation_clause
	end

	def self.add_location_category_filter(aggregation_clause,query_array)
		aggregation_clause << {
			"$match" => {
				"location_categories" => {
					"$in" => query_array.map{|c| c = c["location_categories"]}.flatten
					}
			}
		}
		aggregation_clause
	end

	## @param[Array] query_array
	## @param[Array] aggregation_clause
	def self.unwind_minutes(aggregation_clause)
		aggregation_clause << {
			"$unwind" => "$minutes"	
		}
		aggregation_clause
	end

	## match the catgories as usual, without the duration clause
	def self.add_location_minute_category_filter(aggregation_clause,query_array,ids_or_categories="ids")

		aggregation_clause <<
		{
			"$match" => {
				"$or" => 
				[
						
				]
			}
		}

		## we have to add the duration here.
		## 

		query_array.each do |arr|

			aggregation_clause.last["$match"]["$or"] << {
				"$and" => 
					[
						{
							"minutes.minute" => {
								"$gte" => arr["start_time_range_beginning"],
								"$lte" => arr["start_time_range_end"]
							}
						},
						{
							"minutes.categories" => {
								"$all" => 
								arr["categories"].map{|c|

									qc = {}
									qc["category"] = c["category"]

									if arr["duration"]
										qc["max_free_duration"] = {
											"$gte" => arr["duration"]
										}
									end
									

									c = {
										"$elemMatch" => qc
									}
								}
							}
						}
					]
			}

			if ids_or_categories == "ids"
				aggregation_clause.last["$match"]["$or"].last["$and"] << 
				{ "_id" => arr["location_id"] }
			end 

			if ids_or_categories == "categories"
				aggregation_clause.last["$match"]["$or"].last["$and"] << {
					"location_categories" => {
						"$in" => arr["location_categories"]
					}
				} 
			end

			if arr["consumables"]
				aggregation_clause.last["$match"]["$or"].last["$and"] << 
				{
					"minutes.consumables" => {
						"$all" => []
					}
				}
				arr["consumables"].each do |consumable|
					aggregation_clause.last["$match"]["$or"].last["$and"]["minutes.consumables"]["$all"] << {
						"$elemMatch" => {
							"product_id" => consumable.product_id,
							"quantity" => {
								"$gte" => consumable.quantity
							}
						}
					}	
				end
			end			
		end

		aggregation_clause
	end

	def self.unwind_categories(aggregation_clause)
		aggregation_clause << {
			"$unwind" => "$minutes.categories"	
		}
		aggregation_clause
	end

	def self.add_max_duration_minus_approx_duration_field(aggregation_clause)
		aggregation_clause << {
			"$addFields" => {
				"duration_applicable" => {
					"$subtract" => 
						[
							"$minutes.categories.max_free_duration",
							"$approx_duration"
						]
				}
			}
		}
		aggregation_clause	
	end

	def self.add_duration_applicable_filter(aggregation_clause)
		aggregation_clause << {
			"$match" => {
				"duration_applicable" => {
					"$gte" => 0
				}
			}
		}
		aggregation_clause
	end

	def self.unwind_entities(aggregation_clause)
		aggregation_clause << {
			"$unwind" => "$minutes.categories.entities"	
		}
		aggregation_clause
	end

	def self.regroup_from_minutes(aggregation_clause)
		aggregation_clause << 
		{
			"$group" => {
				"_id" => "$_id",
				"minutes" => {
					"$push" => "$minutes"
				}
			}
		}
		aggregation_clause
	end

	def self.add_entity_transport_filter(aggregation_clause,query_array)

		aggregation_clause <<
		{
			"$match" => {
				"$or" => 
				[
						
				]
			}
		}

		query_array.each do |arr|

			aggregation_clause.last["$match"]["$or"] << 
			{
				"$and" => arr["categories"].map {|category|			
					
					query_clause = {
						"minutes.categories.category" => category["category"],
						"minutes.categories.entities.duration" => {
							"$lte" => arr["duration"]
						}
					}

					
					if category["transport_capacity"]

						query_clause["minutes.categories.entities.transport_capacity"] =
						{
							"$gte" => category["transport_capacity"]
						}  

						query_clause["minutes.categories.entities.departs_from_location_id"] = arr["location_id"].to_s

						query_clause["minutes.categories.entities.arrives_at_location_categories"] = {
							"$in" => category["arrives_at_location_categories"]
						}

					else
					
						query_clause["minutes.categories.capacity"] = {
							"$gte" => category["capacity"]
						}

					end

					category = query_clause
				}
			}
		end

		aggregation_clause
	end

	def self.regroup_from_categories(aggregation_clause)

		aggregation_clause << {
			"$group" => {
				"_id" => "$minutes._id",
				"categories" => {
					"$push" => "$minutes.categories"
				},
				"location" => {
					"$push" => "$_id"
				}
			}	
		}

		## the incoming documents are grouped by minute
		## now all we have to do is group them by the first element in the location.
		aggregation_clause <<
			{
				"$group" => {
					"_id" => {
						"$arrayElemAt" => ["$location",0]
					},
					"minutes" => {
						"$push" => "$$ROOT"
					}	
				}
			}

		aggregation_clause
	end

	def self.regroup_from_entities(aggregation_clause)
		aggregation_clause << {
				"$group" => {
					"_id" => "$minutes.categories._id",
					"category" => {
						"$first" => "$minutes.categories.category"
					},
					"entities" => {
						"$push" => "$minutes.categories.entities"
					},
					"minute" => {
						"$first" => "$minutes._id"
					},
					"minute_actual" => {
						"$first" => "$minutes.minute"
					},
					"location" => {
						"$first" => "$_id"
					}
				}
			}

		aggregation_clause <<
			{
				"$group" => {
					"_id" => "$minute",
					"location" => {
						"$first" => "$location"
						},
					"minute" => {
						"$first" => "$minute_actual"
					},
					"categories" => {
						"$push" => "$$ROOT"
					}	
				}
			}

		aggregation_clause <<
			{
				"$group" => {
					"_id" => "$location",
					"minutes" => {
						"$push" => "$$ROOT"
					}
				}
			}

		aggregation_clause
	end

	


	def self.find_entities_non_transport(query_array)
		aggregation_clause = []
		ids_or_categories = filter_by_location_ids_or_categories?(query_array)
		aggregation_clause = add_location_id_filter(aggregation_clause,query_array) if (ids_or_categories == "ids")
		aggregation_clause = add_location_category_filter(aggregation_clause,query_array) if (ids_or_categories == "categories")
		aggregation_clause = unwind_minutes(aggregation_clause)
		aggregation_clause = add_location_minute_category_filter(aggregation_clause,query_array,ids_or_categories)
		aggregation_clause = regroup_from_minutes(aggregation_clause)
		puts JSON.pretty_generate(aggregation_clause)
		Auth.configuration.location_class.constantize.collection.aggregate(aggregation_clause)
	end

	def self.find_entities_transport(query_array)
		Auth.configuration.location_class.constantize.all.each do |l|
			puts l.id.to_s
		end
		aggregation_clause = []
		ids_or_categories = filter_by_location_ids_or_categories?(query_array)
		aggregation_clause = add_location_id_filter(aggregation_clause,query_array) 
		aggregation_clause = unwind_minutes(aggregation_clause)
		aggregation_clause = add_location_minute_category_filter(aggregation_clause,query_array)
		aggregation_clause = unwind_categories(aggregation_clause)
		aggregation_clause = unwind_entities(aggregation_clause)
		aggregation_clause = add_entity_transport_filter(aggregation_clause,query_array)
		aggregation_clause = regroup_from_entities(aggregation_clause)
		puts JSON.pretty_generate(aggregation_clause)
		Auth.configuration.location_class.constantize.collection.aggregate(aggregation_clause)
	end

	def self.find_entities_within_circle(query_array,coordinates,max_distance)
		aggregation_clause = []
		ids_or_categories = filter_by_location_ids_or_categories?(query_array)
		aggregation_clause = add_geo_filter(aggregation_clause,query_array,coordinates,max_distance,ids_or_categories)
		aggregation_clause = unwind_minutes(aggregation_clause)

		aggregation_clause = add_location_minute_category_filter(aggregation_clause,query_array,ids_or_categories)
		aggregation_clause = regroup_from_minutes(aggregation_clause)
		puts JSON.pretty_generate(aggregation_clause)
		Auth.configuration.location_class.constantize.collection.aggregate(aggregation_clause)
	end

	def self.travel_to_point_with_entities(query_array,coordinates,max_distance,travel_speed)
		aggregation_clause = []
		ids_or_categories = filter_by_location_ids_or_categories?(query_array)
		aggregation_clause = add_geo_filter(aggregation_clause,query_array,coordinates,max_distance,ids_or_categories)
		aggregation_clause = add_approx_duration_field(aggregation_clause,travel_speed)
		aggregation_clause = unwind_minutes(aggregation_clause)
		aggregation_clause = add_location_minute_category_filter(aggregation_clause,query_array,ids_or_categories)
		aggregation_clause = unwind_categories(aggregation_clause)
		aggregation_clause = add_max_duration_minus_approx_duration_field(aggregation_clause)
		aggregation_clause = add_duration_applicable_filter(aggregation_clause)
		aggregation_clause = regroup_from_categories(aggregation_clause)
		puts JSON.pretty_generate(aggregation_clause)
		Auth.configuration.location_class.constantize.collection.aggregate(aggregation_clause)
	end


=begin
	## @use : 
	## Given a point with "#coordinates", we want to find, the nearest location to it, within a distance of #within_radius, that has all the entity "#categories", that are simultaneously free for the time it takes for those entities to reach the point, at a "#speed". THe #minute_range specifies the start minute range for the entities to depart from their locations. The #day_ids specify on which day_ids, we want to search. It will return the nearest location that is found, that satisfies all the above conditions. The returned hash contains all the entities, on that minute, and it also includes the location coordianates and the day_id.
	## @param[Float] speed : speed in m/s at which the entities will cover the distance.
	## @param[Hash] coordinates : a hash which has two keys :- 'lat' and 'lng', representing the latitude and longitude of the point.
	## @param[Float] within_radius : the maximum radius in meters around the #coordinates, in which to search for locations.
	## @param[Array] categories : each element should be a string, which represents a categoSry of the target entity.
	## @param[Array] minute_range :[Range] it conveys a minute in time from midnight(midnight is 0). There should be two elements : eg : [0..100] : means anytime from minute 0 -> minute 100. Max two elements are allowed, first has to be less than or equal to the second.
	## @param[Array] day_ids : an array of integers. ids of days on which to search for the given time range.
	def self.loc(options)


		speed = options[:speed]
		## these are the origin coordinates.
		coordinates = options[:coordinates]
		within_radius = options[:within_radius]
		categories = options[:categories]
		minute_ranges = options[:minute_ranges]
		
		## these two are optional parameters.
		location_categories = options[:location_categories]
		location_ids = options[:location_ids]
		

		raise "speed not provided" if speed.blank?
		raise "either coordinates blank or coordinate latitude or longitude not provided" if (coordinates.blank? || coordinates[:lat].blank? || coordinates[:lng].blank?)
		raise "within radius less than zero" if (within_radius <= 0)
		raise "minute range blank or start minute is greater than end minute" if (minute_ranges.blank?)
		raise "entity categories blank" if categories.blank?
		

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
						"$and" => [
							{
								"minutes.categories" => {
									"$all" => [

									]
								}
							},
							{
								"$or" => [

								]
							}
						]
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
					"minutes.categories" => {
						"$all" => [

						]
					}	
				}
			},
			{
				"$project" => {
					"minutes" => 1,
					"applicable_categories" => {
						"$filter" => {
							"input" => "$minutes.categories",
							"as" => "categs",
							"cond" => {
								"$and" => [
									{ "$in" => 
										[
											"$$categs.category",
											categories
										]
									},
									{
										"$gte" => 
										[
											"$$categs.max_free_duration",
											"$approx_duration"
										]	
									}
								]
							}
						}	
					}
				}
			},
			{
				"$project" => {
					"minutes" => 1,
					"applicable_category_size" => {
						"$size" => "$applicable_categories"
					}
				}
			},
			{
				"$match" => {
					"applicable_category_size" => {
						"$eq" => categories.size
					}
				}
			},
			{
				"$group" => {
					"_id" => "$_id",
					"minutes" => {
						"$push" => "$minutes"
					}
				}
			}
		]


		categories.each do |category|
			aggregation_clause[0]["$geoNear"]["query"]["$and"][0]["minutes.categories"]["$all"] << 
			{
				"$elemMatch" => {
					"category" => category,
					"capacity" => {
						"$gte" => 1
					}
				}
			}
		end

		categories.each do |category|
			aggregation_clause[3]["$match"]["minutes.categories"]["$all"] << 
			{
				"$elemMatch" => {
					"category" => category,
					"capacity" => {
						"$gte" => 1
					}
				}
			}
		end

		## for minute ranges.
		minute_ranges.each do |mrange|
			aggregation_clause[0]["$geoNear"]["query"]["$and"][1]["$or"] << {
				"minutes.minute" => {
					"$gte" => mrange[0],
					"$lte" => mrange[1]
				}
			} 
		end


		if !location_categories.nil?

			aggregation_clause[0]["$geoNear"]["query"]["$and"] << 
				{
					"location_categories" => 
						{
							"$in" => location_categories
						}
				}
		end

		## now add a test for this.

		if !location_ids.nil?

			aggregation_clause[0]["$geoNear"]["query"]["$and"] << 
				{
					"location_ids" => 
						{
							"$in" => location_ids
						}
				}

		end

	
		Auth.configuration.location_class.constantize.collection.aggregate(aggregation_clause)

	end
=end	
=begin
create a geoindex by doing the following command in the mongodb shell
db.my_collection_name.createIndex({location:"2dsphere"});
=end
	
end