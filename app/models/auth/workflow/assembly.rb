class Auth::Workflow::Assembly
  
  include Auth::Concerns::WorkflowConcern

  FIELDS_LOCKED_AFTER_ORDER_ADDED = ["master","applicable"]

  ## set as true if the assembly is to be considered as the master assembly.
  ## can it be set on create ?
  ## no it cannot.
  ## we first clone, for that we provide a master_assembly_id.
  ## then we update something else as the master.
  ## so master cannot be set, on create.
  field :master, type: Boolean, default: false

  ## if the master assembly id is provided, then it will create from that.
  ## inside the create with conditions.
  ## it will verify that at the time of creation, if that is infact the latest master assembly, and only then it will create it.

  ## should the master assembly id be a field, so suppose i entered a master assembly id for this, then it should be easy for us to know that one.
  ## and it should never be possible to change that master id field.
  ## so that parameter is not to be permitted for update.
  ## master is also not be changed once it already exists.
  ## in what sense.
  ## once something is made a master, it cannot be unmade.
  ## also not possible to do that for master_field
  ## master_assembly_id once set cannot be changed, so that will have to be included in all the updates?
  field :master_assembly_id, type: String

  ###########################################################
  ##
  ##
  ##
  ## CLASS METHODS
  ##
  ##
  ## 
  ###########################################################
  def self.permitted_params
    [{:assembly => [:name,:description,:doc_version,:applicable, :master_assembly_id, :master]},:id]
  end

  def self.find_self(id,signed_in_resource,options={})
    
    return nil unless collection =  Auth.configuration.assembly_class.constantize.where("_id" => id
    )

    collection.first
      
  end

  ##########################################################
  ##
  ##
  ##
  ## FOR TESTING PURPOSES
  ##
  ##
  ## Auth::Workflow::Assembly.prepare_nested
  #########################################################
  def self.prepare_nested
    a = Auth::Workflow::Assembly.new
    stage = Auth::Workflow::Stage.new
    sop = Auth::Workflow::Sop.new
    step = Auth::Workflow::Step.new
    sop.steps << step
    stage.sops << sop
    a.stages << stage
    a.save
    a
  end
  ###########################################################
  ##
  ##
  ##
  ## FIELD DEFINITIONS && EMBEDS DEFINITIONS
  ##
  ##
  ##
  ###########################################################  
  field :name, type: String
  field :description, type: String
  embeds_many :stages, :class_name => Auth.configuration.stage_class


  ###########################################################
  ##
  ##
  ## VALIDATIONS
  ##
  ##
  ###########################################################
  ## checks if the provided master assembly id is the latest one.
  ## will check that the existing doc-version is 0 before doing this, so that it only triggers on create!
  validate :master_assembly_id_is_latest_created_master


  ###########################################################
  ##
  ##
  ## CALLBACKS
  ##
  ##
  ###########################################################


 
  ############################################################
  ##
  ##
  ## ELASTICSEARCH MAPPINGS AND DEFS
  ##
  ##
  ############################################################
  include Auth::Concerns::EsConcern	

  INDEX_DEFINITION = {
      index_options:  {
              settings:  {
              index: {
                  analysis:  {
                      filter:  {
                          nGram_filter:  {
                              type: "nGram",
                              min_gram: 2,
                              max_gram: 20,
                              token_chars: [
                                 "letter",
                                 "digit",
                                 "punctuation",
                                 "symbol"
                              ]
                          }
                      },
                      analyzer:  {
                          nGram_analyzer:  {
                              type: "custom",
                              tokenizer:  "whitespace",
                              filter: [
                                  "lowercase",
                                  "asciifolding",
                                  "nGram_filter"
                              ]
                          },
                          whitespace_analyzer: {
                              type: "custom",
                              tokenizer: "whitespace",
                              filter: [
                                  "lowercase",
                                  "asciifolding"
                              ]
                          }
                      }
                  }
              }
            },
              mappings: {
                "workflow/assembly" => {
                _all:  {
                    analyzer: "nGram_analyzer",
                    search_analyzer: "whitespace_analyzer"
                },
                properties: {
                      name: {
                        type: "string",
                        index: "not_analyzed"
                      },
                      description: {
                        type: "string",
                        index: "not_analyzed"
                      }
                }
              }
          }
      }
    }

  create_es_index(INDEX_DEFINITION)

  def as_indexed_json(options={})
     {
        name: name,
        description: description,
        public: public
     }
  end 

  #############################################################
  ##
  ##
  ## MODEL PERSISTENCE DEFINITIONS
  ##
  ##
  #############################################################
  def create_with_conditions(params,permitted_params,model)
    ## in this case the model is a stage model.
    ## we have to set everything other than anything which has an __metadata attribute, and anything else which has
    return false unless (model.valid?)

    ## if the assembly is being created with a master assembly id, then it should 
    if model.master_assembly_id
      ## clone the master
      model = Auth.configuration.assembly_class.constantize.find(master_assembly_id.to_s).clone
    end

    
    assembly_updated = Auth.configuration.assembly_class.constantize.where({
          :_id => model._id
    })
    .find_one_and_update(
      {
        "$set" => model.attributes.except("master")
      },
      {
        :return_document => :after,
        :upsert => true
      }
    )

    #puts assembly_updated.attributes.to_s
    #puts assembly_updated.stages.to_s

    return false unless assembly_updated
    return model


  end



  ## find_self on stage, sop or step -> returns an assembly object
  ## so in any controller, for update, the model will always be an assembly object
  ## so we only work on update_with_conditions for assembly.
  ## permitted params is just the result of calling the permitted params def, and fetching the model from it.
  def update_with_conditions(params,permitted_params,model)
    
    ensure_no_orders = false

    puts "the params are:"
    puts params.to_s

    puts "permitted params are:"
    puts permitted_params.to_s

    _id = permitted_params[:assembly_id] || params[:id] 
    doc_version = permitted_params[:assembly_doc_version] || permitted_params[:doc_version]

    return unless (_id && doc_version)

    query_and_conditions = [
      {
            "_id" => BSON::ObjectId(_id.to_s)
      },
      {

            "doc_version" => doc_version
      },
      {
            "master" => false
      }
    ]

    ## whatever the situation, the master has to be false, for any update to go through.
    ##  

    query = { "$and" => query_and_conditions}

    

    if stage_query = build_stage_query(permitted_params,params)
      query["$and"] = query["$and"] + stage_query
      if sop_query = build_sop_query(permitted_params,params)
        query["$and"] = query["$and"] + sop_query
        if step_query = build_step_query(permitted_params,params)
          query["$and"] = query["$and"] + step_query 
          if requirement_query = build_requirement_query(permitted_params,params)
            query["$and"] = query["$and"] + requirement_query
            if state_query = build_state_query(permitted_params,params)
              query["$and"] = query["$and"] + state_query
            end
          end
        elsif order_query = build_order_query(permitted_params,params)
          query["$and"] = query["$and"] + order_query 
        end
      end
    end


    if state_update = build_state_update(permitted_params,params)
      update = state_update
      ensure_no_orders =  Auth.configuration.state_class.constantize.permitted_params_contain_locked_fields(permitted_params
        )
    elsif requirement_update = build_requirement_update(permitted_params,params)
      update = requirement_update
      ensure_no_orders =  Auth.configuration.requirement_class.constantize.permitted_params_contain_locked_fields(permitted_params
        )
    elsif step_update = build_step_update(permitted_params,params)
      update = step_update
      ensure_no_orders =  Auth.configuration.step_class.constantize.permitted_params_contain_locked_fields(permitted_params
        )
    elsif order_update = build_order_update(permitted_params,params)
      update = order_update
      ensure_no_orders =  Auth.configuration.order_class.constantize.permitted_params_contain_locked_fields(permitted_params
        )
    elsif sop_update = build_sop_update(permitted_params,params)
      update = sop_update
      ensure_no_orders =  Auth.configuration.sop_class.constantize.permitted_params_contain_locked_fields(permitted_params
        )
    elsif stage_update = build_stage_update(permitted_params,params)
      update = stage_update
      ensure_no_orders =  Auth.configuration.stage_class.constantize.permitted_params_contain_locked_fields(permitted_params
        )
    else
      ## its an assembly update.
      ## if the permitted params contain any of the assembly redacted fields, then we have to set ensure_no_orders here as well.    
      ensure_no_orders = Auth.configuration.assembly_class.constantize.permitted_params_contain_locked_fields(permitted_params)    

      model.assign_attributes(permitted_params)

      ## if its only the assembly , then it would just be "$set" => model.attributes
      ## if the master is being set to false, then ensure that it is already false.

      update = {
        "$set" => model.attributes.except("doc_version", "_id", "master_assembly_id"),
        "$inc" => {
          "doc_version" => 1
        }
      }

    end

   
    
    ## ensure that there are no orders anywhere inside assembly, in case we are trying to modify locked fields.
    if ensure_no_orders
        query["$and"] << {
          "stages.sops.orders" => {
            "$exists" => false
          }
        }
    end

    ## now do the where.find_one_and_update
    puts "query is:"
    puts JSON.pretty_generate(query)

    puts "update is:"
    puts JSON.pretty_generate(update)
    

    cl = Auth.configuration.assembly_class.constantize.where(query)

    puts "the results of the query are:"
    puts cl.count.to_s

    Auth.configuration.assembly_class.constantize.where(query).find_one_and_update(update,{:return_document => :after})

  end 

  

  ###########################################################
  ##
  ## getters used in update functions.
  ##
  ###########################################################

  def get_sop(stage_index,sop_index)
    return self.stages[stage_index].sops[sop_index]
  end

  def get_stage(stage_index)
    return self.stages[stage_index]
  end

  def get_step(stage_index,sop_index,step_index)
    return self.stages[stage_index].sops[sop_index].steps[step_index]
  end

  def get_order(stage_index,sop_index,order_index)
    return self.stages[stage_index].sops[sop_index].orders[order_index]
  end

  def get_requirement(stage_index,sop_index,step_index,requirement_index)
    return self.stages[stage_index].sops[sop_index].steps[step_index].requirements[requirement_index]
  end


  def get_state(stage_index,sop_index,step_index,requirement_index,state_index)
    return self.stages[stage_index].sops[sop_index].steps[step_index].requirements[requirement_index].states[state_index]
  end


  def build_stage_query(permitted_params,params)
    stage_index = permitted_params[:stage_index]
    ## why this pipe here?
    ## because if request was made to the stages controller to update a stage, then the stage_id would be the params[:id]
    ## however if the request was made to the sops controller , then the stage_id would explicitly defined as the stage_id, and the :id would actually refer to the sop_id
    ## so first preference is given to that, and params[:id] is the fallback.
    stage_id = permitted_params[:stage_id] || params[:id]
    stage_doc_version = permitted_params[:stage_doc_version] || permitted_params[:doc_version]
    #puts "stage index: #{stage_index}, stage_id: #{stage_id}, stage_doc_version: #{stage_doc_version}"
    return unless (stage_index && stage_id && stage_doc_version)

    query =
      
      [

        {
          "stages.#{stage_index}._id" => BSON::ObjectId(stage_id)     
        },
        {
          "stages.#{stage_index}.doc_version" => stage_doc_version
        }

      ]

    return query

  end

  ## will return nil if the params were not enough
  ## will otherwise return hash 
  ## permitted params are the stage params.
  def build_stage_update(permitted_params,params)
    
    stage_index = permitted_params[:stage_index]
    #stage_id = permitted_params[:stage_id]
    stage_doc_version = permitted_params[:doc_version]
    
    return unless (stage_index && stage_doc_version)

    stage = get_stage(stage_index)
    
    return unless stage

    stage.assign_attributes(permitted_params)
    stage.doc_version = stage_doc_version + 1
   
    update = {
      "$set" => {
        "stages.#{stage_index}" => stage.attributes
      }
    }

    return update

  end


  def build_sop_query(permitted_params,params)

    stage_index = permitted_params[:stage_index]
    stage_id = permitted_params[:stage_id]
    stage_doc_version = permitted_params[:stage_doc_version]
    sop_index = permitted_params[:sop_index]
    ## see the reasons for these pipes in the build_stage_query
    sop_id = permitted_params[:sop_id] || params[:id]
    sop_doc_version = permitted_params[:sop_doc_version] || permitted_params[:doc_version]

    return unless (stage_index && stage_id && stage_doc_version && sop_index && sop_id && sop_doc_version)

    query =
    
      [

        {
          "stages.#{stage_index}.sops.#{sop_index}._id" => BSON::ObjectId(sop_id)     
        },
        {
          "stages.#{stage_index}.sops.#{sop_index}.doc_version" => sop_doc_version
        }

      ]

    return query

  end


  def build_sop_update(permitted_params,params)

    stage_index = permitted_params[:stage_index]
    stage_id = permitted_params[:stage_id]
    stage_doc_version = permitted_params[:stage_doc_version]
    sop_index = permitted_params[:sop_index]
    sop_id = params[:id]
    sop_doc_version =  permitted_params[:doc_version]

    return unless (stage_index && stage_id && stage_doc_version && sop_index && sop_id && sop_doc_version)

    sop = get_sop(stage_index,sop_index)
      
    return unless sop

    sop.assign_attributes(permitted_params)
    sop.doc_version = sop_doc_version + 1

    update = {
      "$set" => {
        "stages.#{stage_index}.sops.#{sop_index}" => sop.attributes
      }
    }

    return update

  end

  def build_step_query(permitted_params,params)

    stage_index = permitted_params[:stage_index]
    stage_id = permitted_params[:stage_id]
    stage_doc_version = permitted_params[:stage_doc_version]
    sop_index = permitted_params[:sop_index]
    sop_id = permitted_params[:sop_id]
    sop_doc_version = permitted_params[:sop_doc_version]
    step_index = permitted_params[:step_index]
    step_id = permitted_params[:step_id] || params[:id]
    step_doc_version = permitted_params[:step_doc_version] ||permitted_params[:doc_version]

    return unless (stage_index && stage_id && stage_doc_version && sop_index && sop_id && sop_doc_version && step_index && step_id && step_doc_version)

    query =
    
      [
        {
          "stages.#{stage_index}.sops.#{sop_index}.steps.#{step_index}._id" => BSON::ObjectId(step_id)     
        },
        {
          "stages.#{stage_index}.sops.#{sop_index}.steps.#{step_index}.doc_version" => step_doc_version
        }
      ]

    return query

  end


  def build_step_update(permitted_params,params)

    stage_index = permitted_params[:stage_index]
    stage_id = permitted_params[:stage_id]
    stage_doc_version = permitted_params[:stage_doc_version]
    
    sop_index = permitted_params[:sop_index]
    sop_id = permitted_params[:sop_id]
    sop_doc_version = permitted_params[:sop_doc_version]
    
    step_index = permitted_params[:step_index]
    step_id = params[:id]
    step_doc_version = permitted_params[:doc_version]


    return unless (stage_index && stage_id && stage_doc_version && sop_index && sop_id && sop_doc_version && step_index && step_id && step_doc_version)

    #puts 'all required params are present.'

    step = get_step(stage_index,sop_index,step_index)
      
    #puts "step got as : #{step}"

    return unless step


    step.assign_attributes(permitted_params)
    step.doc_version = step_doc_version + 1


    update = {
      "$set" => {
        "stages.#{stage_index}.sops.#{sop_index}.steps.#{step_index}" => step.attributes
      }
    }

    return update

  end

  ###### => order query and update

  def build_order_query(permitted_params,params)

    #puts "permitted params are: #{permitted_params}"

    stage_index = permitted_params[:stage_index]
    stage_id = permitted_params[:stage_id]
    stage_doc_version = permitted_params[:stage_doc_version]
    sop_index = permitted_params[:sop_index]
    sop_id = permitted_params[:sop_id]
    sop_doc_version = permitted_params[:sop_doc_version]
    order_index = permitted_params[:order_index]
    order_id = params[:id]
    order_doc_version = permitted_params[:doc_version]

=begin
    puts " ------------------ CAME TO ORDER QUERY --------------"
    puts "stage index : #{stage_index}"
    puts "stage id : #{stage_id}"
    puts "stage doc version: #{stage_doc_version}"
    puts "sop index: #{sop_index}"
    puts "sop id: #{sop_id}"
    puts "sop_doc_version : #{sop_doc_version}"
    puts "order index: #{order_index}"
    puts "order id : #{order_id}"
    puts "order doc version: #{order_doc_version}"

=end
    return unless (stage_index && stage_id && stage_doc_version && sop_index && sop_id && sop_doc_version && order_index && order_id && order_doc_version)

    query =
    
      [
        {
          "stages.#{stage_index}.sops.#{sop_index}.orders.#{order_index}._id" => BSON::ObjectId(order_id)     
        },
        {
          "stages.#{stage_index}.sops.#{sop_index}.orders.#{order_index}.doc_version" => order_doc_version
        }
      ]

    return query

  end

  def build_order_update(permitted_params,params)

    stage_index = permitted_params[:stage_index]
    stage_id = permitted_params[:stage_id]
    stage_doc_version = permitted_params[:stage_doc_version]
    
    sop_index = permitted_params[:sop_index]
    sop_id = permitted_params[:sop_id]
    sop_doc_version = permitted_params[:sop_doc_version]
    
    order_index = permitted_params[:order_index]
    order_id = params[:id]
    order_doc_version = permitted_params[:doc_version]

=begin
    puts " ------------------ CAME TO ORDER UPDATE --------------"
    puts "stage index : #{stage_index}"
    puts "stage id : #{stage_id}"
    puts "stage doc version: #{stage_doc_version}"
    puts "sop index: #{sop_index}"
    puts "sop id: #{sop_id}"
    puts "sop_doc_version : #{sop_doc_version}"
    puts "order index: #{order_index}"
    puts "order id : #{order_id}"
    puts "order doc version: #{order_doc_version}"
=end

    return unless (stage_index && stage_id && stage_doc_version && sop_index && sop_id && sop_doc_version && order_index && order_id && order_doc_version)

    #puts 'ORDER UPDATE -------------all required params are present.'

    order = get_order(stage_index,sop_index,order_index)
      
    #puts "step got as : #{step}"

    return unless order


    order.assign_attributes(permitted_params)
    order.doc_version = order_doc_version + 1


    update = {
      "$set" => {
        "stages.#{stage_index}.sops.#{sop_index}.orders.#{order_index}" => order.attributes
      }
    }

    return update

  end



  ###### => requirement query and update.

  def build_requirement_query(permitted_params,params)

    

    stage_index = permitted_params[:stage_index]
    stage_id = permitted_params[:stage_id]
    stage_doc_version = permitted_params[:stage_doc_version]
    sop_index = permitted_params[:sop_index]
    sop_id = permitted_params[:sop_id]
    sop_doc_version = permitted_params[:sop_doc_version]
    step_index = permitted_params[:step_index]
    step_id = permitted_params[:step_id]
    step_doc_version = permitted_params[:step_doc_version]
    requirement_index = permitted_params[:requirement_index]
    requirement_id = permitted_params[:requirement_id] || params[:id]
    requirement_doc_version = permitted_params[:requirement_doc_version] || permitted_params[:doc_version]

=begin
    puts "stage index: #{stage_index}"
    puts "stage id: #{stage_id}"
    puts "stage doc version: #{stage_doc_version}"

    puts "sop index: #{sop_index}"
    puts "sop id: #{sop_id}"
    puts "sop doc version: #{sop_doc_version}"

    puts "step index: #{step_index}"
    puts "step id: #{step_id}"
    puts "step doc version: #{step_doc_version}"

    puts "requirement index: #{requirement_index}"
    puts "requirement id: #{requirement_id}"
    puts "requirement doc version: #{requirement_doc_version}"
=end
    return unless (stage_index && stage_id && stage_doc_version && sop_index && sop_id && sop_doc_version && step_index && step_id && step_doc_version && requirement_index && requirement_id && requirement_doc_version)



    query =
    
      [
        {
          "stages.#{stage_index}.sops.#{sop_index}.steps.#{step_index}.requirements.#{requirement_index}._id" => BSON::ObjectId(requirement_id)     
        },
        {
          "stages.#{stage_index}.sops.#{sop_index}.steps.#{step_index}.requirements.#{requirement_index}.doc_version" => requirement_doc_version
        }
      ]


   # puts "did not return ---------------------------------"

    return query

  end


  def build_requirement_update(permitted_params,params)

=begin
    puts "came to build requirement update."
    puts "the params are:"
    puts params.to_s
=end
    stage_index = permitted_params[:stage_index]
    stage_id = permitted_params[:stage_id]
    stage_doc_version = permitted_params[:stage_doc_version]
    
    sop_index = permitted_params[:sop_index]
    sop_id = permitted_params[:sop_id]
    sop_doc_version = permitted_params[:sop_doc_version]
    
    step_index = permitted_params[:step_index]
    step_id = permitted_params[:step_id]
    step_doc_version = permitted_params[:step_doc_version]

    requirement_index = permitted_params[:requirement_index]
    requirement_id = params[:id]
    requirement_doc_version = permitted_params[:doc_version]  

=begin
    puts "the params inside the update are-----------"

    puts "stage index: #{stage_index}"
    puts "stage id: #{stage_id}"
    puts "stage doc version: #{stage_doc_version}"

    puts "sop index: #{sop_index}"
    puts "sop id: #{sop_id}"
    puts "sop doc version: #{sop_doc_version}"

    puts "step index: #{step_index}"
    puts "step id: #{step_id}"
    puts "step doc version: #{step_doc_version}"

    puts "requirement index: #{requirement_index}"
    puts "requirement id: #{requirement_id}"
    puts "requirement doc version: #{requirement_doc_version}"

=end
    return unless (stage_index && stage_id && stage_doc_version && sop_index && sop_id && sop_doc_version && step_index && step_id && step_doc_version && requirement_index && requirement_id && requirement_doc_version)

   # puts 'all required params are present.'

    requirement = get_requirement(stage_index,sop_index,step_index,requirement_index)
      
   # puts "requirement got as : #{requirement}"

    return unless requirement

   # puts "found requirement"

    requirement.assign_attributes(permitted_params)
    requirement.doc_version = requirement_doc_version + 1


    update = {
      "$set" => {
        "stages.#{stage_index}.sops.#{sop_index}.steps.#{step_index}.requirements.#{requirement_index}" => requirement.attributes
      }
    }

    return update


  end

  ##### => state query and update.

  def build_state_query(permitted_params,params)

    stage_index = permitted_params[:stage_index]
    stage_id = permitted_params[:stage_id]
    stage_doc_version = permitted_params[:stage_doc_version]
    sop_index = permitted_params[:sop_index]
    sop_id = permitted_params[:sop_id]
    sop_doc_version = permitted_params[:sop_doc_version]
    step_index = permitted_params[:step_index]
    step_id = permitted_params[:step_id]
    step_doc_version = permitted_params[:step_doc_version]
    requirement_index = permitted_params[:requirement_index]
    requirement_id = permitted_params[:requirement_id]
    requirement_doc_version = permitted_params[:requirement_doc_version]
    state_id = params[:id]
    state_doc_version = permitted_params[:doc_version]
    state_index = permitted_params[:state_index]

=begin
    puts "stage index: #{stage_index}"
    puts "stage id: #{stage_id}"
    puts "stage doc version: #{stage_doc_version}"

    puts "sop index: #{sop_index}"
    puts "sop id: #{sop_id}"
    puts "sop doc version: #{sop_doc_version}"

    puts "step index: #{step_index}"
    puts "step id: #{step_id}"
    puts "step doc version: #{step_doc_version}"

    puts "requirement index: #{requirement_index}"
    puts "requirement id: #{requirement_id}"
    puts "requirement doc version: #{requirement_doc_version}"

    puts "state index: #{state_index}"
    puts "state id: #{state_id}"
    puts "state doc version: #{state_doc_version}"
=end

    return unless (stage_index && stage_id && stage_doc_version && sop_index && sop_id && sop_doc_version && step_index && step_id && step_doc_version && requirement_index && requirement_id && requirement_doc_version && state_index && state_id && state_doc_version)



    query =
    
      [
        {
          "stages.#{stage_index}.sops.#{sop_index}.steps.#{step_index}.requirements.#{requirement_index}.states.#{state_index}._id" => BSON::ObjectId(state_id)     
        },
        {
          "stages.#{stage_index}.sops.#{sop_index}.steps.#{step_index}.requirements.#{requirement_index}.states.#{state_index}.doc_version" => state_doc_version
        }
      ]


    puts "STATE_QUERY: ALL PARAMS PRESENt. ---------------------------------"

    return query

  end


  def build_state_update(permitted_params,params)

    #puts "came to build state update."
    #puts "the params are:"
    #puts params.to_s

    stage_index = permitted_params[:stage_index]
    stage_id = permitted_params[:stage_id]
    stage_doc_version = permitted_params[:stage_doc_version]
    
    sop_index = permitted_params[:sop_index]
    sop_id = permitted_params[:sop_id]
    sop_doc_version = permitted_params[:sop_doc_version]
    
    step_index = permitted_params[:step_index]
    step_id = permitted_params[:step_id]
    step_doc_version = permitted_params[:step_doc_version]

    requirement_index = permitted_params[:requirement_index]
    requirement_id = params[:id]
    requirement_doc_version = permitted_params[:doc_version]  

    state_index = permitted_params[:state_index]
    state_id = params[:id]
    state_doc_version = permitted_params[:doc_version]  

=begin
    puts "the params inside the update are-----------"

    puts "stage index: #{stage_index}"
    puts "stage id: #{stage_id}"
    puts "stage doc version: #{stage_doc_version}"

    puts "sop index: #{sop_index}"
    puts "sop id: #{sop_id}"
    puts "sop doc version: #{sop_doc_version}"

    puts "step index: #{step_index}"
    puts "step id: #{step_id}"
    puts "step doc version: #{step_doc_version}"

    puts "requirement index: #{requirement_index}"
    puts "requirement id: #{requirement_id}"
    puts "requirement doc version: #{requirement_doc_version}"


    puts "state index: #{state_index}"
    puts "state id: #{state_id}"
    puts "state doc version: #{state_doc_version}"
=end
    return unless (stage_index && stage_id && stage_doc_version && sop_index && sop_id && sop_doc_version && step_index && step_id && step_doc_version && requirement_index && requirement_id && requirement_doc_version && state_index && state_id && state_doc_version)

   # puts 'all required params are present.'

    state = get_state(stage_index,sop_index,step_index,requirement_index,state_index)
      
   # puts "state got as : #{state}"

    return unless state

   # puts "found requirement"

    ## here we can do the redacting.
    state.assign_attributes(permitted_params)
    state.doc_version = state_doc_version + 1


    update = {
      "$set" => {
        "stages.#{stage_index}.sops.#{sop_index}.steps.#{step_index}.requirements.#{requirement_index}.states.#{state_index}" => state.attributes
      }
    }

    return update


  end

  ###########################################################
  ##
  ##
  ## CUSTOM DEFINITIONS.
  ##
  ##
  ###########################################################
  def master_assembly_id_is_latest_created_master
    return unless self.master_assembly_id
    return unless self.doc_version == 0
    latest_assembly = Auth.configuration.assembly_class.constantize.where({
      "master" => true 
    }).order_by(:created_at => 'desc').limit(1)

    self.errors.add(:master_assembly_id,"this is not the latest master assembly, please check for the latest master assembly, before cloning.") unless latest_assembly.first 

    return if self.errors.full_messages.size > 0

    self.errors.add(:master_assembly_id,"this is not the latest master assembly, please check for the latest master assembly, before cloning.") unless latest_assembly.first.id.to_s == self.master_assembly_id.to_s    
  
  end

  ###########################################################
  ##
  ##
  ##
  ## TRANSACTION BASED DEFS.
  ##
  ##
  ##
  ############################################################
  ## @return[Array] of event objects.
  ## @params[Hash] options : expected to contain a key called product_ids.
  ## 
  def clone_to_add_cart_items(options)
    new_assembly = self.clone

    if new_assembly && new_assembly.save
      resulting_event = Auth::Transaction::Event.new
      resulting_event.object_class = Auth.configuration.sop_class
      resulting_event.method_to_call = "find_applicable_sops"
      resulting_event.arguments = options.merge({:assembly_id => new_assembly.id.to_s})
      return [resulting_event]
    end

    return nil

  end

end
