class Auth::System::Branch

	include Auth::Concerns::SystemConcern
	embeds_many :definitions, :class_name => "Auth::System::Definition"
	embeds_many :units, :class_name => "Auth::System::Unit"
	embedded_in :level, :class_name => "Auth::System::Level"
	field :product_bunch, type: String
	field :merge_output, type: Boolean
	field :input_object_ids, type: Array, default: []
	
	def add_cart_items
		self.definitions.each do |definition|
			definition.add_cart_items(self.input_object_ids.map{|c| c = Auth.configuration.cart_item_class.constantize.find(c)})
		end
	end

	def do_schedule_queries
		self.definitions.each do |definition|
			definition.find_input_object_id_common_schedules
			definition.apply_time_specifications
		end
	end

end