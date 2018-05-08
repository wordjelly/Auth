class Auth::System::Definition

	include Auth::Concerns::SystemConcern
	
	embedded_in :branch, :class_name => "Auth::System::Branch"
	embeds_many :units, :class_name => "Auth::System::Unit"
	
	field :time_specifications, type: Array, default: []
	field :location_specifications, type: Hash, default: {}
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

	## 7th
	def apply_time_specifications

		current_time = Time.now
		self.intersection_results.each_with_index {|intersection_result,key|

			cart_item_ids = self.input_object_ids[key]
			cart_items = cart_item_ids.map{|c| c = Auth.configuration.cart_item_class.constantize.find(c)}
			## now we have to find the time range that is applicable.
			if intersection_result[:minute] == "*"
				start_time_ranges = []
				cart_items.each do |citem|
					## if the cart item has a specification 
					if ((citem.specifications[self.address]) && (citem.specifications[self.address].selected_start_time_range))
						start_time_ranges << citem.specification[self.address].start_time_range
					end
				end
				raise "no start time range found" if start_time_ranges.empty?
			
				start_time_ranges.sort { |a, b| a[:start_time_range_beginning] <=> b[:start_time_range_beginning] }

				first_start_time_beginning = start_time_ranges[0][:start_time_range_beginning]
				first_start_time_end = start_time_ranges[0][:start_time_range_end]

				## now check all the others
				start_time_ranges[1..-1].each do |srange|
					beg = srange[:start_time_range_beginning]
					raise "start time range cannot be synchronized" if beg >= earliest_start_time_end
				end

				## the combined start_time becomes:
				## the end time becomes the earliest of the end times.
				

				final_beginning_time = start_time_ranges[0][:start_time_range_beginning]
				final_end_time = start_time_ranges.map{|c| c = c[:start_time_range_end]}.sort { |a, b| a <=> b }[0]

			else
	
				## check each of the minutes to see if the fulfill the time_specification criteria.


			end
		}
	end

	## 7th
	def apply_location_specifications

	end

	## 8th
	def schedule
		## location query and normal query
		## with capacity.
	end

	def maintain_common_query_hash
		
	end

	## 8th
	def dispatch_to_next_level

	end

	#### how will add_cart_item, delayed_cart_item, worker_sick, delete_cart_item, delete_entire_order, guideline_rescheduling

end