class Auth::Workflow::Slot

	include Auth::Concerns::WorkflowConcern

	embedded_in :booking, :class_name => Auth.configuration.booking_class

	field :start_time, type: String

	field :end_time, type: Integer

end