class Auth::Workflow::Tlocation

	include Auth::Concerns::WorkflowConcern
  	
  	FIELDS_LOCKED_AFTER_ORDER_ADDED = ["applicable","time_information","location_information","follows_previous_step","name"]

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
    attr_accessor :tlocation_index
    
    ## the product id for which the time and scheduling information is being mentioned for this step.
    field :product_id, type: String

    validates_presence_of :product_id

    ## now also add the actual required shit.

    field :time_information, type: Hash

    field :location_information, type: Hash

    field :name, type: String

    field :follows_previous_step, type: String


    ###########################################################
    ##
    ##
    ##
    ##
    ###########################################################

    def self.find_self(id,signed_in_resource,options={})
      return nil unless collection =  Auth.configuration.assembly_class.constantize.where("stages.sops.steps.tlocations._id" => BSON::ObjectId(id)
      )
      collection.first
    end


    def self.permitted_params
      [{:tlocation => [:name, :applicable, :product_id, :assembly_id,:assembly_doc_version,:stage_id, :stage_doc_version, :stage_index, :sop_id, :sop_doc_version, :sop_index, :doc_version, :step_index, :step_id, :tlocation_index, :step_doc_version, :time_information, :location_information, :follows_previous_step]},:id]
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
          },
          {
            "stages.sops.orders" => {
                  "$exists" => false
              }
          }
        ]
      })
      .find_one_and_update(
        {
          "$push" => 
          {
            "stages.#{stage_index}.sops.#{sop_index}.steps.#{step_index}.tlocations" => model.attributes
          }
        },
        {
          :return_document => :after
        }
      )

      

      return false unless assembly_updated
      return model

    end


end