class Auth::Workflow::Entity
		
	include Mongoid::Document

	embedded_in :minute, :class_name => Auth.configuration.minute_class

	field :category, type: String
	
	field :duration, type: Array

	field :booked, type: Boolean

end