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

	

	## suppose we just want the nearest one, then location id is not a must, or it can be an array of location_ids as well.
	## we need a requirement, that is also nearest to our current location.
	## so we can provide a nearest to condition here as well.
	## so frankly speaking, other than the speed step it is the same.
	## category,minute_range,day_ids,location_ids=[]
	def self.find_entity(options)
		return if options[:category].blank?
		return if (options[:minute_range].blank? || options[:minute_range][0] > options[:minute_range][1])
		return if options[:day_ids].blank?
		#return if (location_ids.map{|c| })
		# generate a list of minutes, that can be done, and return the both the list and first minute
		## actually just return the list.
	end


	## @use : 
	## Given a point with "#coordinates", we want to find, the nearest location to it, within a distance of #within_radius, that has all the entity "#categories", that are simultaneously free for the time it takes for those entities to reach the point, at a "#speed". THe #minute_range specifies the start minute range for the entities to depart from their locations. The #day_ids specify on which day_ids, we want to search. It will return the nearest location that is found, that satisfies all the above conditions. The returned hash contains all the entities, on that minute, and it also includes the location coordianates and the day_id.
	## @param[Float] speed : speed in m/s at which the entities will cover the distance.
	## @param[Hash] coordinates : a hash which has two keys :- 'lat' and 'lng', representing the latitude and longitude of the point.
	## @param[Float] within_radius : the maximum radius in meters around the #coordinates, in which to search for locations.
	## @param[Array] categories : each element should be a string, which represents a categoSry of the target entity.
	## @param[Array] minute_range :[Range] it conveys a minute in time from midnight(midnight is 0). There should be two elements : eg : [0..100] : means anytime from minute 0 -> minute 100. Max two elements are allowed, first has to be less than or equal to the second.
	## @param[Array] day_ids : an array of integers. ids of days on which to search for the given time range.
	def self.loc(speed=20,coordinates={:lat => 27.45, :lng => 58.22},within_radius=10000,categories=["1","2","3"],minute_range=[0,100],day_ids=[])

		return if speed.blank?
		return if (coordinates.blank? || coordinates[:lat].blank? || coordinates[:lng].blank?)
		return if (within_radius <= 0)
		return if (minute_range.blank? || minute_range[0] > minute_range[1])
		return if categories.blank?
		return if day_ids.blank?

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
								"minutes.entities" => {
									"$all" => [

									]
								}
							},
							{
								 "day_id" => {
								 	"$in" => day_ids
								 }
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
			aggregation_clause[0]["$geoNear"]["query"]["$and"][0]["minutes.entities"]["$all"] << 
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