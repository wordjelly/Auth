class Auth::Workflow::Assembly
  
  include Mongoid::Document
  include Auth::Concerns::OwnerConcern

  ## these are set from find_self
  attr_accessor :stage_index
  attr_accessor :sop_index
  attr_accessor :step_index

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
    [{:assembly => [:name,:description,:doc_version]},:id,:stage_id, :stage_doc_version, :stage_index, :sop_id, :sop_doc_version, :sop_index]
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
  def update_with_conditions(params,permitted_params,model)
   
    query = [
          {
            "_id" => BSON::ObjectId(model.id.to_s)
          },
          {

            "doc_version" => model.doc_version
          }
    ]

    ## if its only the assembly , then it would just be "$set" => model.attributes
    update = {
      "$set" => model.attributes.except(:doc_version,:_id),
      "$inc" => {
        "doc_version" => 1
      }
    }

    if stage_query = build_stage_query(permitted_params)
      query = query + stage_query
      if sop_query = build_sop_query(permitted_params)
        query = query + sop_query
        if step_query = build_step_query(permitted_params)
          query =  query + step_query 
        end
      end
    end
    
    if step_update = build_step_update(permitted_params)
      update = step_update
    elsif sop_update = build_sop_update(permitted_params)
      update = sop_update
    elsif stage_update = build_stage_update(permitted_params)
      update = stage_update
    end

    ## now do the where.find_one_and_update
    Auth.configuaration.assembly_class.where(query).find_one_and_update(update,{:return_document => :after})

  end 

  
  def get_sop(stage_index,sop_index)
    returns self.stages[stage_index].sops[sop_index]
  end

  def get_stage(stage_index)
    return self.stages[stage_index]
  end

  def get_step(stage_index,sop_index,step_index)
    return self.stages[stage_index].sops[sop_index].steps[step_index]
  end

  def build_stage_query(permitted_params)
    stage_index = permitted_params[:stage_index]
    stage_id = permitted_params[:stage_id]
    stage_doc_version = permitted_params[:stage_doc_version]
    
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
  def build_stage_update(permitted_params)
    
    stage_index = permitted_params[:stage_index]
    stage_id = permitted_params[:stage_id]
    stage_doc_version = permitted_params[:stage_doc_version]
    
    return unless (stage_index && stage_id && stage_doc_version)

    stage = get_stage(stage_index)
      
    return unless stage

    stage.merge(permitted_params.fetch(:stage,{}))
    
    update = {
      "$set" => {
        "stages.#{stage_index}" => stage.attributes.except(:doc_version,:_id)
      },
      "$inc" => {
        "stages.#{stage_index}.doc_version" => 1
      }
    }

    return update

  end


  def build_sop_query(permitted_params)

    stage_index = permitted_params[:stage_index]
    stage_id = permitted_params[:stage_id]
    stage_doc_version = permitted_params[:stage_doc_version]
    sop_index = permitted_params[:sop_index]
    sop_id = permitted_params[:sop_id]
    sop_doc_version = permitted_params[:sop_doc_version]

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


  def build_sop_update(permitted_params)

    stage_index = permitted_params[:stage_index]
    stage_id = permitted_params[:stage_id]
    stage_doc_version = permitted_params[:stage_doc_version]
    sop_index = permitted_params[:sop_index]
    sop_id = permitted_params[:sop_id]
    sop_doc_version = permitted_params[:sop_doc_version]

    return unless (stage_index && stage_id && stage_doc_version && sop_index && sop_id && sop_doc_version)

    sop = get_sop(stage_index,sop_index)
      
    return unless sop

    sop.merge(permitted_params.fetch(:sop,{}))

    update = {
      "$set" => {
        "stages.#{stage_index}.sops.#{sop_index}" => sop.attributes.except(:doc_version,:_id)
      },
      "$inc" => {
        "stages.#{stage_index}.sops.#{sop_index}.doc_version" => 1
      }
    }

    return update

  end

  def build_step_query(permitted_params)

    stage_index = permitted_params[:stage_index]
    stage_id = permitted_params[:stage_id]
    stage_doc_version = permitted_params[:stage_doc_version]
    sop_index = permitted_params[:sop_index]
    sop_id = permitted_params[:sop_id]
    sop_doc_version = permitted_params[:sop_doc_version]
    step_index = permitted_params[:step_index]
    step_id = permitted_params[:step_id]
    step_doc_version = permitted_params[:step_doc_version]

    return unless (stage_index && stage_id && stage_doc_version && sop_index && sop_id && sop_doc_version && step_index && step_id && step_doc_version)

    query =
    
      [
        {
          "stages.#{stage_index}.sops.#{sop_index}.steps.#{step_index}._id" => BSON::ObjectId(sop_id)     
        },
        {
          "stages.#{stage_index}.sops.#{sop_index}.steps.#{step_index}.doc_version" => sop_doc_version
        }
      ]

    return query

  end


  def build_step_update(permitted_params)

    stage_index = permitted_params[:stage_index]
    stage_id = permitted_params[:stage_id]
    stage_doc_version = permitted_params[:stage_doc_version]
    sop_index = permitted_params[:sop_index]
    sop_id = permitted_params[:sop_id]
    sop_doc_version = permitted_params[:sop_doc_version]
    step_index = permitted_params[:step_index]
    step_id = permitted_params[:step_id]
    step_doc_version = permitted_params[:step_doc_version]

    return unless (stage_index && stage_id && stage_doc_version && sop_index && sop_id && sop_doc_version && step_index && step_id && step_doc_version)

    step = get_step(stage_index,sop_index,step_index)
      
    return unless step

    step.merge(permitted_params.fetch(:step,{}))

    update = {
      "$set" => {
        "stages.#{stage_index}.sops.#{sop_index}.steps.#{step_index}" => sop.attributes.except(:doc_version,:_id)
      },
      "$inc" => {
        "stages.#{stage_index}.sops.#{sop_index}.steps.#{step_index}.doc_version" => 1
      }
    }

    return update

  end

end
