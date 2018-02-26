class Auth::Workflow::Assembly
  
  include Mongoid::Document
  include Auth::Concerns::OwnerConcern


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

  INDEX_DEFINITION = {}

  create_es_index(INDEX_DEFINITION)

  def as_indexed_json(options={})

  end

end
