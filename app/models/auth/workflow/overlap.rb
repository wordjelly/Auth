class Auth::Workflow::Overlap

	include Mongoid::Document

	embedded_in :tlocation, :class_name => Auth.configuration.tlocation_class

	field :overlap_eid, type: String

	## the duration of the overlap in seconds
	field :overlap_duration, type: Integer

	## the category of the overlapping entity
	field :overlap_category, type: String

	## the booked type, is the overlap happening booked or free ?
	field :overlap_booked, type: Boolean

end