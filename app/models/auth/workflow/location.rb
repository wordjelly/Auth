class Auth::Workflow::Location

	include Auth::Concerns::WorkflowConcern
	include Mongoid::Geospatial

	## ["collection_center","hematology_station","wash_room"]
	field :location_categories, type: Array

	## make this a location point.
	field :location, type: Point

	
end