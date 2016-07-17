class Admin
  include Mongoid::Document
  include Auth::Concerns::UserConcern
  field :name, type: String
end
