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
				"$addFields" => {
					"cycles.cycle_index" => "$cycle_index"
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

		array_of_minute_objects = []
		response.each do |res|
			#puts JSON.pretty_generate(res)
			array_of_minute_objects << Auth::Work::Minute.new(res)
		end
		array_of_minute_objects
	end

	## @param[Array] minutes : 
	def self.update_affected_minutes(minutes,cycle_workers_assigned,cycle_entities_assigned)

		minutes = minutes.map {|minute|
			
			pull_hash = {}
			
			minute.cycles.each do |cycle|
				pull_hash["cycles.#{cycle.cycle_index}.workers_available"] = {
					"$in" => cycle_workers_assigned
				}				 
			end

			#puts "pull hash is ==================>>>>>>>>>>>>>>>"
			#puts pull_hash.to_s

			minute = Auth::Work::Minute
				.where({
					"_id" => BSON::ObjectId(minute.id.to_s)
				})
				.find_one_and_update(
					{
						"$pull" => pull_hash
					},
					{
						:return_document => :after
					}
				)	
			#puts "updated minute first cycle is:"
			#minute.cycles.each do |cycle|
			#	puts "cycle is: #{cycle.attributes.to_s}"
			#end
			minute
		}

		minutes


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