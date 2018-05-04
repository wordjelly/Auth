class Auth::System::Branch

	include Auth::Concerns::SystemConcern
	embeds_many :definitions, :class_name => "Auth::System::Definition"
	embeds_many :units, :class_name => "Auth::System::Unit"
	embedded_in :level, :class_name => "Auth::System::Level"
	field :product_category, type: String

	## at a certain point the unit will add the products it has to a 

end