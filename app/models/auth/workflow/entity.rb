class Auth::Workflow::Entity
		
	include Mongoid::Document

	embedded_in :category, :class_name => Auth.configuration.category_class
	
	field :duration, type: Integer

	field :booked, type: Boolean



end