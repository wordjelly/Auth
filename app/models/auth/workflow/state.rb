class Auth::Workflow::State

	include Auth::Concerns::WorkflowConcern

  FIELDS_LOCKED_AFTER_ORDER_ADDED = ["applicable"]

	embedded_in :requirement, :class_name => Auth.configuration.requirement_class

	## array of permitted values

	## min value, max value

	## function to set required state, which accepts the orders as input

	## current_value.

	field :permitted_values, type: Array

	field :multiplier_per_cart_item, type: Float

	field :min_value, type: Float

	field :max_value, type: Float

	field :current_value, type: String

  field :name, type: String

	attr_accessor :required_value

	###########################################################

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
  attr_accessor :requirement_doc_version
  attr_accessor :requirement_id
  attr_accessor :state_index


    ###########################################################
    ##
    ##
    ## common methods to all workflow classes
    ##
    ##
    ###########################################################

    def self.find_self(id,signed_in_resource,options={})
      return nil unless collection =  Auth.configuration.assembly_class.constantize.where("stages.sops.steps.requirements.states._id" => BSON::ObjectId(id)
      )
      collection.first
    end

    def self.permitted_params
      [{:state => [:name, :applicable ,:product_id, :reference_requirement, :assembly_id,:assembly_doc_version,:stage_id, :stage_doc_version, :stage_index, :sop_id, :sop_doc_version, :sop_index, :step_doc_version, :step_index, :step_id, :requirement_index, :requirement_doc_version, :requirement_id, :state_index, :doc_version]},:id]
    end

    ###########################################################
    ##
    ##
    ## create method
    ##
    ##
    ###########################################################
    def create_with_conditions(params,permitted_params,model)
    ## in this case the model is a state model.
      
      return false unless model.valid?

=begin
      puts "these are the model attributes --------------"
      puts model.attributes.to_s

      puts model.stage_id
      puts model.stage_doc_version
      puts model.sop_id
      puts model.sop_doc_version
      puts model.step_id
      puts model.step_doc_version
      puts model.requirement_id
      puts model.requirement_doc_version
=end


      query = Auth.configuration.assembly_class.constantize.where({
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
            "stages.#{model.stage_index}.sops.#{model.sop_index}.steps.#{step_index}.requirements.#{requirement_index}._id" => BSON::ObjectId(model.requirement_id)
          },
          {
            "stages.#{model.stage_index}.sops.#{model.sop_index}.steps.#{step_index}.requirements.#{requirement_index}.doc_version" => model.requirement_doc_version
          },
          {
            "stages.sops.orders" => {
                  "$exists" => false
              }
          }
        ]
      })

      puts "the query count is: #{query.size.to_s}"

      assembly_updated = query
      .find_one_and_update(
        {
          "$push" => 
          {
            "stages.#{stage_index}.sops.#{sop_index}.steps.#{step_index}.requirements.#{requirement_index}.states" => model.attributes
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

	def self.setter_function_default
    ## here we have to commit the required value.
    ## it will have to be an update_with_conditions.
		"
			self.required_value = orders.size
		"
	end

	field :setter_function, type: String, default: setter_function_default


	## @param[Array] array of order objects
	## @return[nil] just sets the required_value of this state.
	def calculate_required_state(orders)
		eval(setter_function)
	end



end