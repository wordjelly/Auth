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

	

	
	## @param[Hash] cycles : {cycle_id => cycle}
	## @param[Hash] transport_information : {distance : , coordinates :} 
	## lets get the edit out of the way first.
	def self.find_applicable_minutes(cycles,transport_information={})
		query_clause = {
			"$match" => {
				"$and" => [
					{
						"$or" => 
							[

							]
					},
					{
						"cycles" => {
							"$elemMatch" => {
								"$or" => [
								]
							}
						}
					}
				]
			}
		}

		## that will be one api out of the way.
		## next is also medicine.

		## after this will be the aggregate phase.

		combined_requirements = {}
		individual_requirements = []
		cycles.keys.each do |cycle_id|
			cycle = cycles[cycle_id]
			cycle_clause = {
				"$and" => 
				[

				]
			}
			
			cycle_clause["$and"] << {
				"capacity" => cycle.capacity
			}

			## does the cycle have some kind of type ?
			cycle_clause["$and"] << {
				"cycle_type" => cycle.cycle_type
			}

			query_clause["$match"]["$and"][1]["cycles"]["$elemMatch"]["$or"] << cycle_clause


			cycle_clause_for_entity_types = {
				
			}
			
			cycle.requirements.keys.each do |k|
				combined_requirements[k] = 0 unless combined_requirements[k]
				combined_requirements[k]+= cycle.requirements[k]
				cycle_clause_for_entity_types["entity_types.#{k}"] =
					{
						"$gte" => cycle.requirements[k]
					}
				
			end 

			
			query_clause["$match"]["$and"][0]["$or"] << cycle_clause_for_entity_types			

		end

=begin
		query_clause = [{
			"$match" => {
				"time" => {
					"$exists" => true
				}
			}
		}]
=end		
		puts "this is the generated query clause => "
		puts JSON.pretty_generate(query_clause)


		Auth::Work::Minute.collection.aggregate([query_clause])



	end

end