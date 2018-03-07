class Auth::Workflow::Assembly
  
  include Mongoid::Document
  include Auth::Concerns::OwnerConcern

  ## these are set from find_self
  attr_accessor :stage_index
  attr_accessor :sop_index
  attr_accessor :step_index
  attr_accessor :clone_id

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
    [{:assembly => [:name,:description,:doc_version,:clone_id]},:id]
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
  embeds_many :stages, :class_name => "Auth::Workflow::Stage"


  ###########################################################
  ##
  ##
  ## VALIDATIONS
  ##
  ##
  ###########################################################
  


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
  
  ## find_self on stage, sop or step -> returns an assembly object
  ## so in any controller, for update, the model will always be an assembly object
  ## so we only work on update_with_conditions for assembly.
  ## permitted params is just the result of calling the permitted params def, and fetching the model from it.
  def update_with_conditions(params,permitted_params,model)
   
    query = { "$and" => [
          {
            "_id" => BSON::ObjectId(model.id.to_s)
          },
          {

            "doc_version" => model.doc_version
          }
    ]}

    ## if its only the assembly , then it would just be "$set" => model.attributes
    update = {
      "$set" => model.attributes.except(:doc_version,:_id),
      "$inc" => {
        "doc_version" => 1
      }
    }

    if stage_query = build_stage_query(permitted_params,params)
      puts "got a stage query"

      query["$and"] = query["$and"] + stage_query
      if sop_query = build_sop_query(permitted_params,params)
        query["$and"] = query["$and"] + sop_query
        if step_query = build_step_query(permitted_params,params)
          query["$and"] = query["$and"] + step_query 
        end
      end
    end
    
    if step_update = build_step_update(permitted_params,params)
      update = step_update
    elsif sop_update = build_sop_update(permitted_params,params)
      update = sop_update
    elsif stage_update = build_stage_update(permitted_params,params)
      update = stage_update
    end

    ## now do the where.find_one_and_update
    puts "query is:"
    puts query.to_s

    puts "update is:"
    puts update.to_s
   # Auth.configuration.assembly_class.constantize.where(query).find_one_and_update(update,{:return_document => :after})

    cl = Auth.configuration.assembly_class.constantize.where(query)

    puts "the results of the query are:"
    puts cl.count.to_s

    Auth.configuration.assembly_class.constantize.where(query).find_one_and_update(update,{:return_document => :after})

  end 

  def create_with_conditions(params,permitted_params,model)
    if model.clone_id
      ## go to the root object
      ## clone it and all of its other array friends.
      ## calling clone will call    
          
    end
  end

  def get_sop(stage_index,sop_index)
    return self.stages[stage_index].sops[sop_index]
  end

  def get_stage(stage_index)
    return self.stages[stage_index]
  end

  def get_step(stage_index,sop_index,step_index)
    return self.stages[stage_index].sops[sop_index].steps[step_index]
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
    step_id = params[:id]
    step_doc_version = permitted_params[:doc_version]

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
=end
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

end
