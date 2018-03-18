class Auth::Workflow::Requirement

	  include Mongoid::Document
  	
  	include Auth::Concerns::OwnerConcern
  	
  	embedded_in :step, :class_name => Auth.configuration.step_class
    
    embeds_many :states, :class_name => Auth.configuration.state_class 
   
    field :reference_requirement, type: String

    field :name, type: String

    ## the product id of the requirement.
    field :product_id, type: String


    attr_accessor :assembly_id
    attr_accessor :assembly_doc_version
    attr_accessor :stage_index
    attr_accessor :stage_doc_version
    attr_accessor :stage_id
    attr_accessor :sop_index
    attr_accessor :sop_doc_version
    attr_accessor :sop_id
    attr_accessor :step_index
    attr_accessor :requirement_index
    attr_accessor :requirement_id

    ###########################################################
    ##
    ##
    ##
    ##
    ###########################################################

    def self.find_self(id,signed_in_resource,options={})
      return nil unless collection =  Auth.configuration.assembly_class.constantize.where("stages.sops.steps.requirements._id" => BSON::ObjectId(id)
      )
      collection.first
    end

    def self.permitted_params
      [{:requirement => [:name,:product_id, :reference_requirement, :assembly_id,:assembly_doc_version,:stage_id, :stage_doc_version, :stage_index, :sop_id, :sop_doc_version, :sop_index, :doc_version, :step_index, :requirement_doc_version, :requirement_index]},:id]
    end


    ###########################################################
    ##
    ##
    ## set on calling sufficient.
    ##
    ##########################################################



    def calculate_required_states(orders)
      states.each do |state|
        state.calculate_required_states(orders)
      end
    end


    ## will be called in its own event.
    def mark_requirement

    end
  

end