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
    [{:stage => [:name,:description]},:id]
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

end
