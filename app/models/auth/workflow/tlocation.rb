class Auth::Workflow::Tlocation

  include Auth::Concerns::WorkflowConcern
  	
  embedded_in :location, :class_name => Auth.configuration.location_class

  ## the entity id.
  field :entity_id, type: String

  ## the category of the entity.
  field :entity_category, type: String

  ## the seconds since epoch, after which the entity will be present at the location.
  field :start_time, type: Integer

  ## the seconds since epoch, after which this entity may not be present at this location.
  field :end_time, type: Integer

  ## the difference between the start time and the end time.
  field :duration, type: Integer

  ## whether the slot is deletable, if true, then it will be deleted by a background job after 'n' days.
  field :deletable, type: Boolean, default: false

  ## whether the slot is booked or free, for assignment.
  field :booked, type: Boolean, default: true

  before_save do |document|
    document.duration = document.end_time - document.start_time
  end
  
end