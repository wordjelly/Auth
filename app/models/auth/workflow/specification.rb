class Auth::Workflow::Specification
	include Auth::Concerns::WorkflowConcern
	embedded_in :products, :class_name => Auth.configuration.product_class

	field :address, type: String
	field :start_time_range, type: Array, default: []
	field :end_time_range, type: Array, default: []
	field :target_location, type: Array, default: []
	
end