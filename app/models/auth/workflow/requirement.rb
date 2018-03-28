class Auth::Workflow::Requirement

	  include Auth::Concerns::WorkflowConcern
  	 
    FIELDS_LOCKED_AFTER_ORDER_ADDED = ["applicable","schedulable"]

  	embedded_in :step, :class_name => Auth.configuration.step_class
    
    embeds_many :states, :class_name => Auth.configuration.state_class 
   
    field :reference_requirement, type: String

    field :name, type: String

    ## set to true if this requirement needs to be scheduled.
    ## requirements which are schedulable are skipped during the mark requirement phase.
    field :schedulable, type: Boolean, default: false

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
      [{:requirement => [:name, :applicable, :product_id, :reference_requirement, :assembly_id,:assembly_doc_version,:stage_id, :stage_doc_version, :stage_index, :sop_id, :sop_doc_version, :sop_index, :doc_version, :step_index, :step_id, :requirement_index, :step_doc_version, :schedulable]},:id]
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

    def calculate_required_states(orders)
      states.each do |state|
        state.calculate_required_states(orders)
      end
    end

    ## basically we want to combine all the states required values to search for and mark the product.
    ## we have to call eval on it.
    ## so here what we will do is to 
    def self.state_query_update_combiner_default
        "
        product_query = {
          \"$and\" => [
            { \"_id\" => BSON::ObjectId(arguments[:requirement][:product_id])
            }
          ]
        }

        product_update = {}

        arguments[:requirement][:states].each do |state|
          
          if state[:setter_function] == Auth.configuration.state_class.constantize.setter_function_default

            product_query[\"$and\"] << {
              \"stock\" => {
                \"$gte\" => state[:required_value].to_f
              }
            }

            product_update[\"$inc\"][:stock] = options[:required_stock]*-1
             
          end

        end

        ## at the end it should do that query.
        return Auth.configuration.product_class.constantize.where(product_query).find_one_and_update(product_update,{:return_document => :after})
        "
    end

    field :state_query_update_combiner, type: String, default: state_query_update_combiner_default

    ## please note that you have to provide that product as is.
    ## @param[Hash] arguments : passed in from the mark_requirement, commit the required_value.
    def execute_product_mark(arguments)
      eval(state_query_update_combiner)
    end 

    ## @param[Hash] arguments : the same arguments hash that was passed into #mark_requirement function.
    ## @return[Array] array with a single event.
    def emit_schedule_sop_event(arguments)
        e = Auth::Transaction::Event.new
        e.arguments = arguments
        e.method_to_call = "schedule_order"
        [e]
    end
    ###########################################################
    ##
    ##
    ## EVENT BASED METHODS.
    ##
    ##########################################################
    
    ## now if the product mark is successfull then and only then, 
    def mark_requirement(arguments={})
      return nil if (arguments[:requirement].blank?)
      execute_product_mark(arguments) unless self.schedulable 
      return emit_schedule_sop_event(arguments) if arguments[:last_requirement] == true
      return [] 
    end

    

end