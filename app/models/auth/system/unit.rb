class Auth::System::Unit
	include Auth::Concerns::SystemConcern
	embedded_in :definition, :class_name => "Auth::System::Definition"
	field :query_results, type: Array
	field :input_object_ids_index, type: Integer
	field :output_cart_item_ids, type: Array
end	