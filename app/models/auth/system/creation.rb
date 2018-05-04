class Auth::System::Creation
	include Auth::Concerns::SystemConcern
	embedded_in :defintion, :class_name => "Auth::System::Definition"
	embeds_many :outputs, :class_name => "Auth::System::Output"
	field :applicable_to_product_ids, type: Array
	field :summatable, type: Boolean
	field :rounding_factor, type: Float

end