class Auth::Workflow::Location

	include Auth::Concerns::WorkflowConcern
	include Mongoid::Geospatial

	## ["collection_center","hematology_station","wash_room"]
	field :location_categories, type: Array

	## make this a location point.
	field :location, type: Point

	## embeds many some kind of object
	## let us use tlocation for this.

	embeds_many :tlocations, :class_name => Auth.configuration.tlocation_class
	
=begin
create a geoindex by doing the following command in the mongodb shell
db.my_collection_name.createIndex({location:"2dsphere"});
=end
	
end