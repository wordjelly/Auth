class Auth::System::Wrapper

	include Auth::Concerns::SystemConcern
	embeds_many :levels, :class_name => "Auth::System::Level"
	field :cart_item_ids, type: Array

	


end