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


end