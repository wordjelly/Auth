class Auth::Work::Entity
	include Mongoid::Document
	field :cycle_type, type: String
end