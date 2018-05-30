class Auth::System::Transporter

	include Mongoid::Document

	embedded_in :instant, :class_name => "Auth::System::Instant"


	field :entity_id, type: String
	field :radius, type: Float
	field :capacity, type: Integer

	## instead of this we will use entities.

end