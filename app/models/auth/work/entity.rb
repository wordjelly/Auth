class Auth::Work::Entity
	include Mongoid::Document
	field :cycle_types, type: Hash
end