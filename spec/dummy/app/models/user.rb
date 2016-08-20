class User
  include Mongoid::Document
  include Auth::Concerns::UserConcern
  field :name, type: String
  field :dog, type: String
end
