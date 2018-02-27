class Auth::Workflow::Sop
  include Mongoid::Document
  embeds_many :steps, :class_name => "Auth::Workflow::Step"
  embedded_in :stage, :class_name => "Auth::Workflow::Stage"
  field :name, type: String
  attr_accessor :stage_id
end
