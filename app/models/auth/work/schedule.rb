class Auth::Work::Schedule

	include Mongoid::Document

	field :start_time, type: Time
	field :end_time, type: Time
	field :location_id, type: String
	field :for_object_id, type: String
	field :for_object_class, type: String
	field :can_do_cycles, type: Array, default: []

	def create_prev_not_exists
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
					"$setOnInsert" => self.attributes
				},
				{
					:upsert => true,
					:new => true
				}
			)
		
	end

end