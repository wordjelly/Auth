class Auth::Workflow::Category
	include Mongoid::Document
	embedded_in :minute, :class_name => Auth.configuration.minute_class
	embeds_many :entities, :class_name => Auth.configuration.entity_class
	## now what fields should this have ?
	field :category, type: String
	field :capacity, type: Integer
	field :max_free_duration, type: Integer
	
end