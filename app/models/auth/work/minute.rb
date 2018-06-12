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

	def self.update_all_affected_cycles(minutes,cycle_workers_assigned,cycle_entities_assigned)
		update_cycle_chains(minutes)
		update_cycles(minutes,cycle_workers_assigned,cycle_entities_assigned)
	end

	## @param[Array] minutes : 
	def self.update_cycles(minutes,cycle_workers_assigned,cycle_entities_assigned)

		minutes = minutes.map {|minute|
			
			pull_hash = {}
			
			minute.cycles.each do |cycle|
				pull_hash["cycles.#{cycle.cycle_index}.workers_available"] = {
					"$in" => cycle_workers_assigned
				}				 
			end

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
			
			minute
		}

		minutes

	end

	## first knock of the cycle chains.
	## then the actual cycles.
	def self.update_cycle_chains(minutes)
		cycles_to_pull = []
		minutes.each do |minute|
			minute.cycles.each do |cycle|
				cycles_to_pull << cycle.cycle_chain
			end
		end

		cycles_to_pull.flatten.map{|c| c = BSON::ObjectId(c)}.each_slice(100) do |ids_to_pull|
			pull_hash = {}
			pull_hash["cycles"] = {
				"_id" => {
					"$in" => ids_to_pull
				}
			}
			response = Auth::Work::Minute.collection.update_many({},{"$pull" => pull_hash})
		end

		cycles_to_pull.flatten	
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