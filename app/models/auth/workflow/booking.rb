class Auth::Workflow::Booking

	include Auth::Concerns::WorkflowConcern

	embedded_in :schedule, :class_name => Auth.configuration.schedule_class

	embeds_many :slots, :class_name => Auth.configuration.slot_class

	field :requirement_id, type: String

	field :requirement_capacity, type: Integer

	field :requirement_category, type: String


end