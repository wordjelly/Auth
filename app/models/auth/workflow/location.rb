class Auth::Workflow::Location

	include Auth::Concerns::WorkflowConcern
	include Mongoid::Geospatial

	## ["collection_center","hematology_station","wash_room"]
	field :location_categories, type: Array

	## make this a location point.
	field :location, type: Point

	## create a geoindex by doing the following command in the mongodb shell

=begin
db.my_collection_name.createIndex({location:"2dsphere"});
=end
	
end