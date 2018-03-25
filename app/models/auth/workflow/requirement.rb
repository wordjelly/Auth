class Auth::Workflow::Requirement

	  include Auth::Concerns::WorkflowConcern
  	 
    FIELDS_LOCKED_AFTER_ORDER_ADDED = ["applicable"]

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
    attr_accessor :step_doc_version
    attr_accessor :step_id
    attr_accessor :requirement_index
   
    

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
      [{:requirement => [:name, :applicable, :product_id, :reference_requirement, :assembly_id,:assembly_doc_version,:stage_id, :stage_doc_version, :stage_index, :sop_id, :sop_doc_version, :sop_index, :doc_version, :step_index, :step_id, :requirement_index, :step_doc_version]},:id]
    end

    ###########################################################
    ##
    ##
    ## create method
    ##
    ##
    ###########################################################
    def create_with_conditions(params,permitted_params,model)
    ## in this case the model is a stage model.
      
      return false unless model.valid?

      puts "these are the model attributes --------------"
      puts model.attributes.to_s

      assembly_updated = Auth.configuration.assembly_class.constantize.where({
        "$and" => [
          {
            "stages.#{model.stage_index}._id" => BSON::ObjectId(model.stage_id)
          },
          {
            "stages.#{model.stage_index}.doc_version" => model.stage_doc_version
          },
          {
            "_id" => BSON::ObjectId(model.assembly_id)
          },
          {
            "doc_version" => model.assembly_doc_version
          },
          {
            "stages.#{model.stage_index}.sops.#{model.sop_index}._id" => BSON::ObjectId(model.sop_id)
          },
          {
            "stages.#{model.stage_index}.sops.#{model.sop_index}.doc_version" => model.sop_doc_version
          },
          {
            "stages.#{model.stage_index}.sops.#{model.sop_index}.steps.#{step_index}._id" => BSON::ObjectId(model.step_id)
          },
          {
            "stages.#{model.stage_index}.sops.#{model.sop_index}.steps.#{step_index}.doc_version" => model.step_doc_version
          }
        ]
      })
      .find_one_and_update(
        {
          "$push" => 
          {
            "stages.#{stage_index}.sops.#{sop_index}.steps.#{step_index}.requirements" => model.attributes
          }
        },
        {
          :return_document => :after
        }
      )

      

      return false unless assembly_updated
      return model

    end

    ###########################################################
    ##
    ##
    ## EVENT BASED METHODS.
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