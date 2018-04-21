class Auth::Workflow::Schedule

	include Auth::Concerns::WorkflowConcern
	
	field :assembly_id, type: String
	
	field :order_id, type: String

	embeds_many :bookings, :class_name => Auth.configuration.booking_class

end