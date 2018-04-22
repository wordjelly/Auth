class Auth::Workflow::Tlocation

	include Auth::Concerns::WorkflowConcern
    
  field :requirement_id, type: String

  field :requirement_category, type: String

  field :start_time, type: Integer

  field :end_time, type: Integer

  field :deletable, type: Boolean, default: false

  embedded_in :location, :class_name => Auth.configuration.location_class
  
end