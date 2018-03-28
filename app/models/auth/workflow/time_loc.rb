class TimeLoc

	include Auth::Concerns::WorkflowConcern
  	
  	FIELDS_LOCKED_AFTER_ORDER_ADDED = ["applicable"]

  	embedded_in :step, :class_name => Auth.configuration.step_class

  	attr_accessor :assembly_id
    attr_accessor :assembly_doc_version
    attr_accessor :stage_index
    attr_accessor :stage_doc_version
    attr_accessor :stage_id
    attr_accessor :sop_index
    attr_accessor :sop_doc_version
    attr_accessor :sop_id
    attr_accessor :step_index
    attr_accessor :step_doc_version
    attr_accessor :step_id
    attr_accessor :timeloc_index
   
    field :product_id, type: String

    validates_presence_of :product_id

    ## now also add the actual required shit.

    field :time_information, type: Hash

    field :location_information, type: Hash

end