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

	## this will block the transporter and rewire his availability for all subsequent and prior minutes.
	## this i have to do today.
	def update_transporter

	end

	## TODO -> are teh 30 minute rolling cycles also deleted ?

	## so we are going to
	## the minute has cycles
	## given a bunch of cart items, we are going to land up with a bunch of cycles that are going to have to be done.
	## so we need a minute where all these cycles are possible.
	## or at least as many of them as possible.
	## we are going to need cycles with enough workers as well.
	## and enough entities.
	## it may be that a cycle exists, but it should have enough workers and entities to do the job.
	## okay so if we have found such cycles, now we want 
	## we can label them as rolling
	## and then we can count how many we got.
	## match where [cycle is a and cycle is primary] OR [cycle is b and cycle is primary, cycle is c and cycle is primary] present.
	## then unwind the cycles
	## so now we know that all these cycles even if they don't be primary, still belong to a minute with a primary
	## now match only the useful cycles
	## group by minutes
	## add a field that combines the size of the avialable cycles + the distance from now
	## sort by that.
	def find_applicable_minute

	end

end