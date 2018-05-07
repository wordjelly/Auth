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
						"$in" => self.input_object_id_group
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

		response.each do |res|
			puts res["query_results"].to_s
		end

		response
	end

	## 7th
	def find_input_object_id_common_schedules
		self.input_object_ids.each do |input_object_id_group|
			agg = input_object_query_results(input_object_id_group)
			query_results_array = []
			agg.each do |res|
				query_results_array << res["query_results"]
			end
			## now this query results array has to be intersected.
			## using bsearch.
			## we need to find common applicable minutes.
			## for all the things together.
		end
	end

	## 7th
	def apply_time_specifications

	end

	## 7th
	def apply_location_specifications

	end

	## 8th
	def schedule
		## location query and normal query
		## with capacity.
	end

	## 8th
	def dispatch_to_next_level

	end

	#### how will add_cart_item, delayed_cart_item, worker_sick, delete_cart_item, delete_entire_order, guideline_rescheduling

end