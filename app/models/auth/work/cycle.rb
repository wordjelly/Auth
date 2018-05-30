class Auth::Work::Cycle
		
	include Mongoid::Document

	## each cycle will have a limit
	field :capacity, type: Integer
	## it will have a time at which starts
	field :start_time, type: Time
	## it will have a list of workers to whom it is assigned
	field :workers_assigned, type: Array

	## it will have a list of machines on which it is going to be performed.
	field :machines, type: Array
	
	## it will have a bunch of steps to be followed by doing it.
	field :steps, type: Array
	
	## it accepts input objects
	## these have n number of products in them
	## and this cycle, will be generating stuff out of that
	embeds_many :inputs, :class_name => "Auth::Work::Input"
		
	## it has to have a priority score
	field :priority, type: Float

	
	
end