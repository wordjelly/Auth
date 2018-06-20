class Auth::Work::Minute
	
	include Mongoid::Document
	
	embeds_many :cycles, :class_name => "Auth::Work::Cycle", :as => :minute_cycles
	
	field :time, type: Time
	
	field :geom, type: Array

	## this includes workers and entities, and actually anything that could be needed for the cycle.
	field :entity_types, type: Hash, default: {}

	## next step is to pull correctly.
	## so this done.
	def update_entity_types
		#puts "came to update entity types"
		applicable_schedules = Auth::Work::Schedule.collection.aggregate([
			{
				"$match" => {
					"$and" => [
						{
							"start_time" => {
								"$lte" => self.time
							}
						},
						{
							"end_time" => {
								"$gte" => self.time
							}
						}
					]
				}
			}
		])

		applicable_schedules.each do |schedule|
			sched = Auth::Work::Schedule.new(schedule)
			object = sched.for_object_class.constantize.find(sched.for_object_id)
			object.cycle_types.keys.each do |k|
				self.entity_types[k]+=1 if self.entity_types[k]
				self.entity_types[k]= 1 unless self.entity_types[k]
			end
		end

	end

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

	

	## okay first do what can be predictable done.
	## that means the partials in the views.
	## go for it.

	## match where [cycle is a and cycle is primary] OR [cycle is b and cycle is primary, cycle is c and cycle is primary] present.
	## then unwind the cycles
	## so now we know that all these cycles even if they don't be primary, still belong to a minute with a primary
	## now match only the useful cycles
	## group by minutes
	## add a field that combines the size of the avialable cycles + the distance from now
	## sort by that.
	## @param[Array] cycle_requirements_array : {cycle_id , worker_requirements :{"type" : number}, entity_requirements: {"type" : number}}
	## @param[Hash] transport_information : {distance : , coordinates :} 
	## lets get the edit out of the way first.
	def find_applicable_minute(cycle_requirements_array)
		## go to elasticsearch for this ?
		## ?
		aggregations = [
			{
				"cycles" => {
					"$elemMatch" => {
						"$or" => 
						[

						]
					}
				}	
			},
			{
				"$unwind" => "$cycles"
			},
			{
				## keep all cycles, dont enforce the belongs_to_minute at this level.
				## just cycle_type and workers and entities
				## since we want to include the 30 min rolling slots as well.
				## we are only keeping the cycles which have the required type.
				## and we can match again, 
				"$match" => {
					"cycles.cycle_type" => {
						"$in" => "all_the_cycles"
					}
				} 
			}
		]



		cycle_requirements_array.each do |req|
			aggregations[0]["cycles"]["$elemMatch"]["$or"] << {
				"cycle_type" => req["cycle_type"], 
				"workers_available.#{req['workers_count'] - 1}" => {
					"$exists" => true
				},
				"entities_available.#{req['entities_count'] - 1}" => {
					"$exists" => true
				},
				"belongs_to_minute" => true
			}
		end

		## we are going to get minutes that have at the minimum one of the cycles as belonging to the given minute.

		## now we are going to unwind the cycles, 
		## keep only those which satisfy these conditions.

		## we take a look at other cycles which will be affected only if that cycle, is not already booked, otherwise it doesnt make any difference at all.

	end

end