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

	## okay now how will this work
	## its like we generate an array 
	## and then is it possible to do it faster?
	## suppose we just want the nearest one, then location id is not a must, or it can be an array of location_ids as well.
	## we need a requirement, that is also nearest to our current location.
	## so we can provide a nearest to condition here as well.
	## so frankly speaking, other than the speed step it is the same.
	## category,minute_range,day_ids,location_ids=[]
	def self.find_entity(options)

		## required parameters
		categories = options[:categories]
		minute_ranges = options[:minute_ranges]
		duration = options[:duration]

		raise "categories not provided" if categories.blank?
		raise "minute_ranges not provided" if minute_ranges.blank?
		raise "duration not provided" if duration.blank?

		## optional parameters
		location_ids = options[:location_ids]
		location_categories = options[:location_categories]

		aggregation_clause = 
		[
			{
			"$match" => 
				{
					"$and" 	=> 	
					[
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
			},
			{
				"$unwind" => "$minutes"
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

		if !location_ids.nil?
			aggregation_clause[0]["$match"]["$and"] << 
				{
					"_id" => 
					{
						"$in" => location_ids.map{|c| c = BSON::ObjectId(c)}
					}
				}

		end
	
			
		if !location_categories.nil?
			aggregation_clause[0]["$match"]["$and"] << 
				{
					"location_categories" => 
						{
							"$in" => location_categories
						}
				}
		end 

		
		categories.each do |category|
			aggregation_clause[0]["$match"]["$and"][0]["minutes.categories"]["$all"] << 
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
			aggregation_clause[0]["$match"]["$and"][1]["$or"] << 
			{
				"minutes.minute" => {
					"$gte" => mrange[0],
					"$lte" => mrange[1]
				}
			} 
		end

		Auth.configuration.location_class.constantize.collection.aggregate(aggregation_clause)

	end


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
	
=begin
create a geoindex by doing the following command in the mongodb shell
db.my_collection_name.createIndex({location:"2dsphere"});
=end
	
end