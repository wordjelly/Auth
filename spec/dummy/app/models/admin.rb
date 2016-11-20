class Admin
  include Mongoid::Document
  include Auth::Concerns::UserConcern
  field :role, type: String
end
