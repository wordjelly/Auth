class Topic
  include Mongoid::Document
  field :name, type: String
  field :place, type: String
end
