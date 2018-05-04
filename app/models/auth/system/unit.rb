class Auth::System::Unit
	include Auth::Concerns::SystemConcern
	embedded_in :definition, :class_name => "Auth::System::Definition"
	field :query_results, type: Array
	field :creation_id, type: String
	field :output_ids_to_generated_object_ids, type: Hash
end	