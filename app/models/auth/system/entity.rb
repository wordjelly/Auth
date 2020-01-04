class Auth::System::Entity
	include Mongoid::Document
	embedded_in :minute, :class_name => "Auth::System::Minute"
	field :product_id, type: String
	field :capacity, type: Float
	field :free_duration, type: Integer 
end