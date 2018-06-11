class Auth::Work::Minute
	include Mongoid::Document
	embeds_many :cycles, :class_name => "Auth::Work::Cycle", :as => :minute_cycles
	field :time, type: Time
	field :geom, type: Array
	


	## returns all minutes which have affected cycles , only containing the affected cycles.
	## does not consider the cycle chains.
	def self.get_affected_minutes(cycle_start_time,cycle_end_time,cycle_workers_assigned,cycle_entities_assigned)
		response = Auth::Work::Minute.collection.aggregate([
			{
				"$match" => {
					"cycles" => {
						"$elemMatch" => {
							"$and" => [
								{
									"$or" => [
										{
											"start_time" => {
												"$gte" => cycle_start_time,
												"$lte" => cycle_end_time 
											}
										},
										{
											"end_time" => {
												"$gte" => cycle_start_time,
												"$lte" => cycle_end_time
											}
										},
										{
											"$and" => [
												{
													"start_time" => {
														"$lte" => cycle_start_time
													}
												},
												{
													"end_time" => {
														"$gte" => cycle_end_time
													}
												}
											]
										}
									]
								},
								{
									"$or" => [
										{
											"workers_available" => {
												"$in" => cycle_workers_assigned
											}
										},
										{
											"entities_available" => {
												"$in" => cycle_entities_assigned
											}
										}
									]
								}
							]
						}
					}
				}
			},
			{
				"$unwind" =>
				{
					"path" => "$cycles",
					"includeArrayIndex" => "cycle_index"
				}
			},
			{
				"$match" => {
					"$and" => [
						{
							"$or" => [
								{
									"cycles.start_time" => {
										"$gte" => cycle_start_time,
										"$lte" => cycle_end_time 
									}
								},
								{
									"cycles.end_time" => {
										"$gte" => cycle_start_time,
										"$lte" => cycle_end_time
									}
								},
								{
									"$and" => [
										{
											"cycles.start_time" => {
												"$lte" => cycle_start_time
											}
										},
										{
											"cycles.end_time" => {
												"$gte" => cycle_end_time
											}
										}
									]
								}
							]
						},
						{
							"$or" => [
								{
									"cycles.workers_available" => {
										"$in" => cycle_workers_assigned
									}
								},
								{
									"cycles.entities_available" => {
										"$in" => cycle_entities_assigned
									}
								}
							]
						}
					]
				}
			},
			{
				"$group" => {
					"_id" => "$_id",
					"cycles" => {
						"$push" => "$cycles"
					}
				}
			}
		])
		response
	end

	## this means that the cycle has to be keeping track of the workers available and entities_available.
	## but what about capacity ?
	## so now we are getting the list of the affected cycles
	## now we have to write one function to reduce the workers/entities there.
	## and also of those cycle chains.
	## so while searching you will search for a cycle with at least required number of workers and required number of entities.
	## so we will query the length or we will remove the assigned and available workers.
	## also write the function to update those cycles.

end