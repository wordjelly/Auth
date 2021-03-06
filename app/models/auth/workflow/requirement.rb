class Auth::Workflow::Requirement

	  include Auth::Concerns::WorkflowConcern
  	 
    FIELDS_LOCKED_AFTER_ORDER_ADDED = ["applicable","schedulable","resolve_requirement","location_information","time_information"]

  	embedded_in :step, :class_name => Auth.configuration.step_class
    
    embeds_many :states, :class_name => Auth.configuration.state_class 
  
    ## eg: stages.1.sops.2.steps.4.requirements.4
    field :reference_requirement_address, type: String



    ## if true will not create a new entry in the schedule query hash for this requirement.
    ## otherwise will create.
    field :follow_reference_requirement, type: Boolean, default: false

    ## if this is set to true, will have to 

    field :name, type: String

    ## set to true if this requirement needs to be scheduled.
    ## requirements which are schedulable are skipped during the mark requirement phase.
    field :schedulable, type: Boolean, default: false


    ## the product id of the requirement.
    field :product_id, type: String

    #validates_presence_of :product_id


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
      [{:requirement => [:name, :applicable, :product_id, :reference_requirement, :assembly_id,:assembly_doc_version,:stage_id, :stage_doc_version, :stage_index, :sop_id, :sop_doc_version, :sop_index, :doc_version, :step_index, :step_id, :requirement_index, :step_doc_version, :schedulable, :resolve_requirement, :location_information, :time_information]},:id]
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

    ## @param[Integer] index : the index of the requirment inside the step.
    ## @return[String] address : something like : "stages:0:sops:1:steps:2:requirements:3"
    def get_self_address(index)
      "stages:#{self.stage_index}:sops:#{self.sop_index}:steps:#{self.step_index}:requirements:#{index}"
    end


    def calculate_required_states(order)
      states.each do |state|
        state.calculate_required_state(order)
      end
    end

    ## basically we want to combine all the states required values to search for and mark the product.
    ## we have to call eval on it.
    ## so here what we will do is to 
    def self.state_query_update_combiner_default
        ## we can find the relevant product.
        ## but thereafter, if we have to do it again
        ## then what ?
        ## it will have to be an upsert of some kind.
        ## for a particular requirement has the thing already been booked, for a particular order?
        ## how to do that?
        ## the product has a huge bunch of orders
        ## see the requirements hard code the product ids.
        ## or should they hardcode product categories?
        ## then they will have a product category.
        ## suppose you want a product nearby?
        ## then how does it work?
        ## it is like a large number of things with a product code.
        ## and we search where, order.requirement_address does not exist, and product code is as per other requirements -> there we update.
        ## so if that query changes, then this will also change.
        ## so what is different form ths 


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
      result_of_marking_product = eval(state_query_update_combiner)
      puts "result of marking product is: #{result_of_marking_product}"
    end 

    ## @param[Hash] arguments : the same arguments hash that was passed into #mark_requirement function.
    ## @return[Array] array with a single event.
    def emit_schedule_sop_event(arguments)
        e = Auth::Transaction::Event.new
        e.arguments = arguments
        e.method_to_call = "schedule_order"
        [e]
    end


    def add_to_query_hash(stage_index,sop_index,step_index,req_index,query_hash,force=false)
      
      if force
      
        query_hash["stages.#{self.stage_index}.sops.#{self.sop_index}.steps.#{key}.requirements.#{req_index}"] = self

      else

        if self.follow_reference_requirement
          query_hash[self.reference_requirement_address].add_requirement(self)
        else
          query_hash["stages.#{self.stage_index}.sops.#{self.sop_index}.steps.#{key}.requirements.#{req_index}"] = self
        end

      end

    end


    ## a subsequent requirement is adding itself to this requirement.
    def add_requirement(req)
      ## take the duration from its time_information and add it to the self duration
      self.time_information[:duration] += req.time_information[:duration]
    end


    

    ## adds the duration of the step itself to this requirements time information.
    ## also updates the end_time so that it reflects the duration of the step.
    def add_duration_from_step(step_duration)
      self.time_information[:duration] = step_duration
      self.time_information[:end_time] = self.time_information[:end_time] + self.time_information[:duration]
    end
    


    ## modulates the end time and start time to reflect the total elapsed duration since the start of the sop.
    def add_duration_since_first_step(duration_since_start)
      self.time_information[:duration_since_start] = duration_since_start
      self.time_information[:start_time] = self.time_information[:start_time] + self.time_information[:duration_since_start]
      self.time_information[:end_time] = self.time_information[:end_time] + self.time_information[:duration_since_start]
    end


    def build_query(query)
      #########################################################
      ##
      ## TIME INFORMATION
      ##
      #########################################################
      query["$or"] << {"$and" => []} 

      query["$or"].last["$and"] << generate_time_query


      #########################################################
      ##
      ## LOCATION INFORMATION
      ##
      #########################################################
      
      query["$or"].last["$and"] << generate_location_query

      
      #########################################################
      ##
      ## REQUIREMENT INFORMATION
      ##
      #########################################################
      ## add the requirement category 
      ## if the requirement was resolved, then add resolved_id

      if self.resolved_id
        query["$or"].last["$and"] << {
          "requirement_ids" => self.resolved_id
        }
      else
        query["$or"].last["$and"] << {
          "requirement_categories" => self.category
        }
      end


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