class Auth::Work::Schedule

	include Mongoid::Document

	field :applicable_to_cycles, type: Array, default: []
	field :start_time, type: Time
	field :end_time, type: Time
	field :location_id, type: String
	field :for_object_id, type: String
	field :for_object_class, type: String
	field :can_do_cycles, type: Array

	def create_schedule
		Auth::Work::Schedule.find_and_update
		## find where
		## start time < and end_time within_or equal
		## or
		## start time = and end_within or equal
		## or
		## start_time > and end_time equal or within.
		## and then upsert
		## if n modified is not one.
		## return the schedule or nil.
		created_document = Auth::Work::Schedule.
			where({
				"$and" => [
					{
						"location_id" => self.location_id
					},
					{
						"for_object_id" => self.for_object_id
					},
					{
						"for_object_class" => self.for_object_class
					},
					{
						"$or" => [
							{
								## the end time is within this start - end time
								"end_time" => {
									"$lte" => self.end_time,
									"$gte" => self.start_time
								}
								
							},
							{
								## the start time is within this start - end time.
								"start_time" => {
									"$gte" => self.start_time,
									"$lte" => self.end_time
								}
									
							},
							{
								## the start time is less than or equal to this start time, and the end time is greater than or equal to this end time.(envelope)
								"$and" => [
									"start_time" => {
										"$lte" => self.start_time
									},
									"end_time" => {
										"$gte" => self.end_time
									}
								]
							}
						]
					}
				]
			}).
			find_one_and_update(
				{
					"$setonInsert" => self.attributes
				},
				{
					:return_document => :after,
					:upsert => true
				}
			)

		return created_document
	end

	## so cycles are polymorphically embedded in minutes and products
	## schedules store the cycle_code , as got from products
	## then when cycles are to be added to the minutes, it takes each product, it checks which cycles are there in that product and at what interval, it then gets all the entities and workers that are applicable to each cycle, and adds them to each and every minute, and the subsequent cycles to the correctly intervaled minutes.
	## okay so next step is to do this part.
	## and today check out auth api and deploy it to aws simply.
end