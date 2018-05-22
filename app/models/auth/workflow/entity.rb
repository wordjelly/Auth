class Auth::Workflow::Entity
		
	include Mongoid::Document

	embedded_in :category, :class_name => Auth.configuration.category_class
	
	field :duration, type: Integer

	field :booked, type: Boolean

	## a location id from which this entity is going to depart.
	field :departs_from_location_id, type: String

	## the location categories of the location from which this entity is departing.
	field :location_categories_for_departs_from, type: Array

	## a location id to which this entity is going.
	field :arrives_at_location_id, type: String

	## the location categories of the location to which this entity is going to arrive.
	field :arrives_at_location_categories, type: Array	

	## modify overlap hash to do what we need it to do
	## each array of the query ids, will hold infact a smaller hash
	## this hash will have
	## query_id => [capacity,type]
	## so query ids will actually be a hash, and not an array, 
	## it will have 
	## what all will this change ?
	## it will change, the basic hash that is being created to be inserted
	## it will also change the process of filtration.
	field :arrives_at_location_coordinates, type: Array, default: []

	field :transport_capacity, type: Float
end