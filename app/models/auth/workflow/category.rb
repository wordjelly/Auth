class Auth::Workflow::Category
	include Mongoid::Document
	embedded_in :minute, :class_name => Auth.configuration.minute_class
	embeds_many :entities, :class_name => Auth.configuration.entity_class
	## now what fields should this have ?
	field :category, type: String
	field :capacity, type: Integer
	field :max_free_duration, type: Integer
		
	## THESE ACCESSORS ARE REQUIRED WHILE DOING THE GROUP STAGES IN THE AGGREGATIONS, AND ARE NOT NEEDED OR USED ANYWHERE
	attr_accessor :location
	attr_accessor :minute
	attr_accessor :minute_actual
	
	
	def get_types_for_overlap_hash
		## how will this work
		## what is the first thing that has to be done.
		
	end

	## today i want to complete transport query and the location id filter in the minute query.
	## and also its integration into the overlap hash.


end