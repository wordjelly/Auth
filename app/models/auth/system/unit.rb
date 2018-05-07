class Auth::System::Unit
	include Auth::Concerns::SystemConcern
	embedded_in :definition, :class_name => "Auth::System::Definition"
	field :definition_plus_input_group_id, type: String
	field :query_results, type: Array
end	