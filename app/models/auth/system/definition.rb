class Auth::System::Definition

	include Auth::Concerns::SystemConcern
	
	embedded_in :branch, :class_name => "Auth::System::Branch"
	embeds_many :units, :class_name => "Auth::System::Unit"
	
	field :time_specifications, type: Array, default: []
	field :location_specifications, type: Array, default: []
	field :duration, type: Integer
	field :entity_categories_needed_simultaneously_with_capacity, type: Hash, default: {}
	field :physical_requirements, type: Hash, default: {}
	field :merge_output, type: Boolean, default: false
	field :output_objects, type: Hash, default: {}
	field :input_requirements, type: Array, default: []
	field :input_object_ids, type: Array, default: []
	
	## whether the locations of incoming objects inside each object_id element are to be kept common?
	field :intersection_location_commonality, type: Boolean, default: false
	
	## the results of the intersects, one for each element in the input object ids.
	field :intersection_results, type: Array, default: []

	## can we store this in the time specifications.?
	## 
	
	## @return[Boolean] true/false : depending on whether anything could be added to this definition or not.
 	def add_cart_items(input_objects)
		groups = {}
		input_objects.each do |input_object|
			if group_value = input_object.get_group_value(self.address)
				groups[group_value] = [] unless groups[group_value]
				groups[group_value] << input_object.id.to_s
			end
		end
		groups.values.each do |val|
			self.input_object_ids << val
		end
		!groups.empty?
	end

	## @param[Array] input_object_id_group : we consider one element at a time of the input_object_ids, which is an array of arrays. So one array is passed in at a time, and that is called input_object_id_group
	## @return[MongoDb::Aggregation::Response] : the result of the aggregation. It should have as many elements as the input_object_id_group and each element has only the query_results available on it.
	def input_object_query_results(input_object_id_group)
		response = Auth::System::Wrapper.collection.aggregate([
			{
				"$match" => {
					"levels.branches.definitions.units.output_cart_item_ids" => {
						"$in" => input_object_id_group
					}
				}
			},
			{
				"$unwind" => {
					"path" => "$levels"
				}
			},
			{
				"$unwind" => {
					"path" => "$levels.branches"
				}	
			},
			{
				"$unwind" => {
					"path" => "$levels.branches.definitions"
				}
			},
			{
				"$unwind" => {
					"path" => "$levels.branches.definitions.units"
				}
			},
			{
				"$match" => {
					"output_cart_item_ids" => {
						"$in" => self.input_object_ids
					}	
				}
			},
			{
				"$project" => {
					"query_results" => 1
				}
			}
		])

		## the query results contain what?
		## just the minutes or is each element a hash?
		## it should be a hash
		## like minute : [locations...]

		response.each do |res|
			puts res["query_results"].to_s
		end

		response
	end

	## 7th
	def find_input_object_id_common_schedules
		self.input_object_ids.each_with_index {|input_object_id_group,key|
			
			agg = input_object_query_results(input_object_id_group)
			
			query_results_array = []
			
			agg.each do |res|
				query_results_array << res["query_results"]
			end
			
			combined_array = []
			
			if query_results_array.empty?
=begin
				 if it is the first time, then the time information would normally look at the intersects for the query.
				 so we just put a "*" in the intersects.
				 the intersect results usually have 
				 [[{},{},{}],[{},{},{}]]
				 so in this case, we will push an array, with one hash , where the minute will be * and the locations will be an array with one *
				

				[
					[
						{
							:minute => "*",
						 	:locations => ["*"]
						 }
					]
				]
=end				
				combined_array = 
				[
					{
						:minute => "*",
						:locations => ["*"]
					}
				]

			else
			
				query_results_array.first.each do |minute_hash|
					minute = minute_hash[:minute]
					locations = minute_hash[:locations]
					query_results_array[1..-1].each do |arr|
						if result = arr.bsearch{|x| x[:minute] >= minute}
							if result[:minute] == minute
								if intersection_location_commonality
									if (result[:locations] - locations).size > 0
										combined_array << result
									end
								else
									combined_array << result
								end
							end
						end
					end
				end
			
			end

			intersection_results << combined_array
		}
	end

	## let me first individually test this function.
	def apply_time_specifications

		current_time = Time.now
		
		self.intersection_results.each_with_index {|intersection_result,key|

			cart_item_ids = self.input_object_ids[key]
			cart_items = cart_item_ids.map{|c| c = Auth.configuration.cart_item_class.constantize.find(c)}
			
			if intersection_result[0][:minute] == "*"
				start_time_ranges = []
				cart_items.each do |citem|
					## we have to see if the specifications contain this address or not.
					if specification = citem.get_specification(self.address)
						start_time_ranges << specification.start_time_range(current_time)
					end
				end

				raise "no start time range found" if start_time_ranges.empty?
	
				start_time_ranges.sort { |a, b| a[:start_time_range_beginning] <=> b[:start_time_range_beginning] }

				first_start_time_beginning = start_time_ranges[0][:start_time_range_beginning]
				first_start_time_end = start_time_ranges[0][:start_time_range_end]

				## now check all the others
				start_time_ranges[1..-1].each do |srange|
					beg = srange[:start_time_range_beginning]
					raise "start time range cannot be synchronized" if beg >= first_start_time_end
				end

				## the combined start_time becomes:
				## the end time becomes the earliest of the end times.
				
				final_beginning_time = start_time_ranges[-1][:start_time_range_beginning]
				final_end_time = start_time_ranges.map{|c| c = c[:start_time_range_end]}.sort { |a, b| a <=> b }[0]

				time_specifications << {:start_time_range_beginning => final_beginning_time, :start_time_range_end => final_end_time}

			else
				



			end
		}
	end

	## 7th
	def apply_location_specifications

		## each intersection result refers to one "product" or "product_equivalent" coming in.
		self.intersection_results.each_with_index {|intersection_result,key|

			cart_item_ids = self.input_object_ids[key]
			cart_items = cart_item_ids.map{|c| c = Auth.configuration.cart_item_class.constantize.find(c)}

			if intersection_result[0][:locations] == ["*"]

				within_radius_type_location_specifications = 0

				loc_sp = {:loc_id_type => [], :within_radius_type => []}

				cart_items.each do |citem|
					if specification = citem.get_specification(self.address)

						if location_information = specification.location

							if location_information[:within_radius]
								loc_sp[:within_radius_type] << location_information unless location_information[:within_radius].nil?
								raise "more than one within radius type of location" unless loc_sp[:within_radius_type].include? location_information	
							else
								loc_sp[:loc_id_type] << location_information
							end

						end

					end
				end

				common_location_ids = nil

				if loc_sp[:loc_id_type].size > 0

					#puts "the first loc_sp loc_id_type"
					#puts loc_sp[:loc_id_type][0].to_s

					common_location_ids = loc_sp[:loc_id_type].inject(loc_sp[:loc_id_type][0][:location_ids]){|result,el| result = result & el[:location_ids]}

					#puts "the common location ids are:"
					#puts common_location_ids

					raise "could not find common location ids" if common_location_ids.size == 0
				end

				if loc_sp[:within_radius_type].size == 1
					if common_location_ids
						coords = loc_sp[:within_radius_type][0][:origin_location]
						within_radius = loc_sp[:within_radius_type][0][:within_radius]
						permitted_location_categories = loc_sp[:within_radius_type][0][:location_categories]
				
						common_location_ids = validate_locations_within_radius(common_location_ids,coords,within_radius,permitted_location_categories)
						if common_location_ids.size > 0
							## these should be added to the location specifications.
							self.location_specifications << {:location_ids => common_location_ids}
						else
							raise "could not find common location ids" if common_location_ids.size == 0
						end
					else
						## in this case there is only a single within_radius_type of location specifications, and nothing else.
						## so here it will carry all the location information only.
						self.location_specifications << loc_sp[:within_radius_type][0]
					end

				else
					if common_location_ids.nil?
						self.location_specifications << {}
					else
						self.location_specifications << {:location_ids => common_location_ids}
					end
				end

			else

				## here it will depend on the location ids specified in the intersects.
				## and how to apply these.

			end
		}

	end

	## will take the time and location information and make queries.
	def search_locations
		## if it is a within radius type, then it is one possibility, otherwise it is a simple location category search.
		## and what kind of result output is necessary.
		## and what about the situation where no location information is specified for the query, in that case, empty shit should get passed into the array of location information.
		## so first let me add a test for that.
	end

	## @param[Array] location_ids : the location ids which we want to check are within the radius for the provided coordinates. This is an array of strings.
	## @param[Hash] coordinates : the coordinates of the origin point.
	## @param[Float] within_radius : the radius within the coordinates where to look if the location ids lie.
	## @return[Array] location_ids_satisfying_conditions : the location ids which lie within the radius of the coordinates.  
	def validate_locations_within_radius(location_ids,coordinates,within_radius,location_categories)

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
							 	"_id" => {
							 		"$in" => location_ids
								 }
							 }
						 ]
					}
				}
			},
			{
				"$limit" => location_ids.size
			},
			{
				"$project" => {
					"_id" => 1
				}
			}
		]

		if location_categories
			aggregation_clause[0]["$geoNear"]["query"]["$and"] << {
				"location_categories" => {
					"$in" => location_categories
				}
			}
		end

		response = Auth.configuration.location_class.constantize.collection.aggregate(aggregation_clause)


		location_ids_satisfying_conditions = []
		response.each do |res|
			location_ids_satisfying_conditions << res["_id"]
		end


		return location_ids_satisfying_conditions

	end

end