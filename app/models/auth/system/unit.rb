class Auth::System::Unit
	include Auth::Concerns::SystemConcern
	embedded_in :definition, :class_name => "Auth::System::Definition"
	field :query_results, type: Array
	field :input_object_ids_index, type: Integer
	field :output_cart_item_ids, type: Array

	## will generate barcodes, and callouts based on the incoming options.
	def generate_barcodes_and_callouts(options)

	end

	## should return instructions inside the definition that are to be updated.
	def generate_new_instructions(options)

	end

	def update_video_and_photo_interactions(options)

	end

end	