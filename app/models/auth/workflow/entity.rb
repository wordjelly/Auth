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

	field :arrives_at_location_coordinates, type: Array, default: []

	field :transport_capacity, type: Float

	
	def get_type
		return "default" unless arrives_at_location_id
		return departs_from_location_id.to_s + "_" + arrives_at_location_id.to_s
	end
end