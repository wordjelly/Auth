class Auth::Workflow::Minute

	include Mongoid::Document

	embedded_in :location, :class_name => Auth.configuration.location_class

	## the minimum duration of all the entities embedded in this minute.
	field :minimum_entity_duration, type: Integer

	## an integer is assigned to every minute from 0 -> 1439 for 11.59
	field :minute, type: Integer

	## this tells the exact hour and minute that this minute represents.
	field :hour_description, type: String

	embeds_many :categories, :class_name => Auth.configuration.category_class
	
	embeds_many :consumables, :class_name => Auth.configuration.consumable_class

	

end