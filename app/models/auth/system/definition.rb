class Auth::System::Definition
	include Auth::Concerns::SystemConcern
	embedded_in :branch, :class_name => "Auth::System::Branch"
	embeds_many :creations, :class_name => "Auth::System::Creation"
	embeds_many :units, :class_name => "Auth::System::Unit"
	field :product_requirements, type: Hash
	field :time_specifications, type: Array
	field :location_specifications, type: Hash
	field :duration, type: Integer
	field :entity_categories_needed_simultaneously_with_capacity, type: Hash


end