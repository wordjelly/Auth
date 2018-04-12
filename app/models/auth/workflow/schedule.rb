class Auth::Workflow::Schedule

	include Auth::Concerns::WorkflowConcern
	
	field :assembly_id, type: String
	
	field :stage_id, type: String

	field :stage_index, type: Integer

	field :sop_id, type: String

	field :sop_index, type: Integer
	
	field :sop_end_time, type: Integer
	
	field :order_id, type: String

	field :cart_item_ids, type: Array

end