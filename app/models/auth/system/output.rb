class Auth::System::Output
	include Auth::Concerns::SystemConcern
	embedded_in :creation, :class_name => "Auth::System::Creation"
	field :product_id, type: String
	field :destination_address, type: String
	field :quantity_per_incoming_product, type: Float
end