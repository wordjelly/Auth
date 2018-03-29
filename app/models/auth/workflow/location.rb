class Auth::Workflow::Location

	include Auth::Concerns::WorkflowConcern

	## ["collection_center","hematology_station","wash_room"]
	field :location_categories, type: Array

	## make this a location point.
	field :point

end