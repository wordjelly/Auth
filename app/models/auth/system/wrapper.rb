class Auth::System::Wrapper

	include Auth::Concerns::SystemConcern
	embeds_many :levels, :class_name => "Auth::System::Level"
	
	before_save do |document|
		document.add_addresses
	end

	#################### OVERLAP HASH FUNCTIONS ##########################

=begin
	STRUCTURE OF OVERLAP HASH
	-------------------------

	{
		"location_id" : {
			"minute_range_start" : {
					"combination_of_categories" : {:query_ids => []}
			},
			"minute_range_end" : {
					"combination_of_categories" : {:query_ids => []}
			}
		}
	}
=end

	field :overlap_hash, type: Hash, default: {}

	## we can make a seperate overlap hash for consumables or seperate keys inside each minute for consumables and categories
	## let us have a seperate key inside each minute.
	## finish quickly.
		
	## @param[Hash] existing : the existing hash at the minute.
	## @param[Hash] incoming : the incoming hash that we want to merge, this will be with two keys : {:categories_hash => {}. :consumables_hash => {}}
	## @return[Hash] existing : after merging in the incoming hash.
	def merge_minute_hash(fused,incoming)
		existing = fused.deep_dup
		
		puts "existing is:"
		puts JSON.pretty_generate(existing)

		puts "incoming is:"
		puts JSON.pretty_generate(incoming)

		## now comes the question of how we are going to merge this stuff exactly ?
		## 
		## check the category combination.

		incoming[:categories].keys.each do |category_combination|
			if existing[:categories][category_combination]
				puts "found category combination #{category_combination}"

				incoming[:categories][category_combination][:query_ids].keys.each do |q_id|

					puts "searching query id: #{q_id}"

					if existing[:categories][category_combination][:query_ids][q_id]

						puts "query id exists #{q_id}"

						incoming[:categories][category_combination][:query_ids][q_id].keys.each do |cat|


							## we will have to search all the query ids, in the existing for this category, and if we find it , then we can proceed.
							if existing[:categories][category_combination][:query_ids][q_id][cat]

								incoming[:categories][category_combination][:query_ids][q_id][cat].keys.each do |type|

									if existing[:categories][category_combination][:query_ids][q_id][cat][type]

										existing[:categories][category_combination][:query_ids][q_id][cat][type] += incoming[:categories][category_combination][:query_ids][q_id][cat][type] 
									
									else

										existing[:categories][category_combination][:query_ids][q_id][cat][type] = incoming[:categories][category_combination][:query_ids][q_id][cat][type] 

									end

								end

							else
								existing[:categories][category_combination][:query_ids][q_id][type] = incoming[:categories][category_combination][:query_ids][q_id][cat]
							end

						end

					else
				
						existing[:categories][category_combination][:query_ids][q_id] = incoming[:categories][category_combination][:query_ids][q_id]
					end
				end

			else
				
				existing[:categories][category_combination] = incoming[:categories][category_combination]
			end
		end


		incoming[:consumables].keys.each do |product_id|
			## do we already have this product_id ?
			if existing[:consumables][product_id]
				existing[:consumables][product_id] << incoming[:consumables][product_id]
			else
				existing[:consumables][product_id] =  incoming[:consumables][product_id]
			end
		end

		existing

	end

	## @param[Hash] minute_hash_to_insert : the query id and the categories for the minute we are wanting to insert. e.g : {categories_to_fuse.to_s => {:categories => [array_of_categories], query_ids => [query_id]}}
	## @param[Integer] minute : either the start or end_minute.
	## @param[String] location_id : the id of the location.
	## @return[nil]
	def manage_minute(minute_hash_to_insert,minute,location_id)
				
		puts "this is the minute to insert."
		puts "minute to insert is: #{minute}"

		location_id = location_id.to_s.to_sym

		## it depends if the location already exists in the location hash.
		self.overlap_hash[location_id] = {} unless self.overlap_hash[location_id]

		existing_minutes = self.overlap_hash[location_id].keys.map{|c| c = c.to_s.to_i}.sort { |a, b| a <=> b }

		if existing_minutes.size > 0

			equal_to_minute = minute.to_i if existing_minutes.include? minute.to_i

			less_than_minute = nil

			greater_than_minute = nil

			unless equal_to_minute
				existing_minutes.each_with_index {|min,index|
					## if you find something greater
					## then stop
					## whatever is before was less
					if (min > minute.to_i)
						greater_than_minute = min
						## if we have something before, i.e if the index is >= 1
						less_than_minute = existing_minutes[index - 1] if index >=1
						break
					else
						if index == (existing_minutes.size - 1)
							less_than_minute = min.to_i
						end
					end
				}
			end


			## suppose there is an equal to , then we have to fuse it with that.
			## **(minute).............
			if equal_to_minute 


				self.overlap_hash[location_id][minute.to_s.to_sym] =  merge_minute_hash(self.overlap_hash[location_id][minute.to_s.to_sym],minute_hash_to_insert)
			
			else

				## only less than or only greater than, and equal to is nil.
				## **..........(minute) || (minute)............**
				if ((less_than_minute && greater_than_minute.nil?) || (less_than_minute.nil? && greater_than_minute))
					#puts "EITHER ONLY LESS OR ONLY GREATER."
					self.overlap_hash[location_id][minute.to_s.to_sym] = minute_hash_to_insert 
				end

				## less than and greater than, and equal to is nil
				## **................(minute)...............**
				if greater_than_minute && less_than_minute
					#puts "------- GOT THE LESS THAN AND GREATER THAN BOTH ---- "
					## in this case we want to fuse in the less than minute with this one and add it in.
					fused_hash = merge_minute_hash(self.overlap_hash[location_id][less_than_minute.to_s.to_sym],minute_hash_to_insert)

					self.overlap_hash[location_id][minute.to_s.to_sym] = fused_hash
				end

			end

			## there is one more possibility where there is nothing else.
			## in that case, we have to add the start and end minute direct.
		else
			self.overlap_hash[location_id][minute.to_s.to_sym] = minute_hash_to_insert 
		end

	end

	## finds all the minutes in between the newly inserted start and end minute, and fuses the minute_hash into them.
	## @param[Hash] minute_hash_to_insert : the query id and the categories for the minute we are wanting to insert. e.g : {categories_to_fuse.to_s => {:categories => [array_of_categories], query_ids => [query_id]}}
	## @param[Integer] start_minute : the start_minute for the location_id.
	## @param[Integer] end_minute : the end_minute for the location_id.
	## @param[String] location_id : the location id.
	## @return[nil]
	def update_intervening_minutes(minute_hash_to_insert,start_minute,end_minute,location_id)
		location_id = location_id.to_s.to_sym

		existing_minutes = self.overlap_hash[location_id].keys.map{|c| c = c.to_s.to_i}.sort { |a, b| a <=> b }

		existing_minutes.each do |min|
			if ((min > start_minute) && (min < end_minute))
				self.overlap_hash[location_id][min.to_s.to_sym] = merge_minute_hash(self.overlap_hash[location_id][min.to_s.to_sym],minute_hash_to_insert)
			end
		end

	end

	

	## let me first test uptil here.


	## Adds the results of the query to the overlap hash, these results should be pre-filtered.
	## @param[Mongo::Aggregation] query_result : the result of the mongodb aggregation.
	## @param[Array] categories_searched_for : the categories_searched_for in the query.
	## @param[String] query_id : the arbitarily assigned id to the query.
	## @param[Array] consumables_searched_for : array of consumable objects.
	## @return[nil]
	def update_overlap_hash(query_result,query_array,query_id)
		query_result.each do |location|
			
			puts JSON.pretty_generate(location)
			
			location_id = location["_id"]
			
			start_minute = Auth::Workflow::Minute.new(location["minutes"].first)
			end_minute = Auth::Workflow::Minute.new(location["minutes"].last)


			if (start_minute && end_minute)
			
				manage_minute(end_minute.minute_to_insert(query_id),end_minute.minute,location_id)

				if(start_minute.minute != end_minute.minute)
					manage_minute(start_minute.minute_to_insert(query_id),start_minute.minute,location_id)
					update_intervening_minutes(start_minute.minute_to_insert(query_id),start_minute.minute,end_minute.minute,location_id)
				end
			
			end

		end


	end

	## lets say i get a range of minutes
	## now i dispatch to the next layer
	## we know we can start anytime from the first -> last minute.
	## i can store the minutes
	## that's the only way really.
	## and thereafter i can store subsequent things in those minutes
	## so we have a hash like this:
=begin
	{
		root_query => {
			min_1 => for min 1 to be viable,
			min_2
			min_3
			min_4
		}
	}
=end
	## @param[String] query_result_id : the id of the incoming query result.
	## @param[Array] category_combination_query_ids : the query_ids of the category_combination inside the applicable minute in the overflow hash.
	## @return[Array] applicable_query_ids : the query ids which are applicable to @query_result_id.
	def applicable_query_ids(query_result_id,category_combination_query_ids)

		## for now this returns the whole combination of shit.
		return category_combination_query_ids

	end

=begin
basically how this works is as follows : - 
1. for each location in the result
	-iterate each minute
	-check which categories are present in that minute : "minute_categories"
	- now find a minute in the overlap hash that is applicable to this minute (equal, or such that this minute is between two other minutes.)
	- iterate each category combination stored in this minute
	- does the category combination have any category in common with what we searched for ?
	- yes
		- in order for the minute in the query result to be constrained by this category combination, it will have to have all the categories in this category combination, so does it ?
		- yes
			- now we have to check how many query ids in the query ids of this category combination, are applicable to our incoming query id.
			- that is the required capacity for the common categories in the query result minute.
		- no  
	- no

=end


	
	## will first convert the query result into an array
	def filter_query_results(query_result,query_array,query_id)
		query_result = query_result.to_a
		## this is going to be a hash
		## the problem is that we wont have the types
		## how to know the type ?
		## we need to know what is the 
		categories_searched_for = query_array.first["categories"].map{|c| c = c["category"]}

		category_quantities = query_array.first["categories"].map{|c| 
			c = [c["category"].to_sym,(c["transport_capacity"] || c["capacity"])]
		}.to_h


			
		consumables_searched_for = []
		if query_array.first["consumables"]
			consumables_searched_for = query_array.first["consumables"].map{|c| c = Auth.configuration.consumable_class.constantize.new(c)}
		end

		indices_of_minutes_to_prune = {}

		query_result.each_with_index {|location,location_index|
			
			indices_of_minutes_to_prune[location_index] = []

			location_overlap_hash = self.overlap_hash[location["_id"].to_s.to_sym]
			
			next unless location_overlap_hash

			sorted_minutes = location_overlap_hash.keys.map{|c| c = c.to_s.to_i}.sort { |a, b| a<=>b }

			location["minutes"].each_with_index{|minute_hash,index|

				## if you require only one type per category, then there is no problem.
				## we can just double it, whatever is coming in.
				category_requirements = categories_searched_for.map{|c| c = [c.to_sym,{}]}.to_h


				
				### have to initialize it with whatever were our entity requirements for the current query.
				### but i dont know that exact combination.
				## that is the issue.
				## so here there are two options.
				## one is that we have to know the type before hand
				## or two it has to know if this type fits.
				## 

				consumable_requirements = consumables_searched_for.map{|c| c = [c.product_id.to_s,c.quantity]}.to_h if consumables_searched_for

				minute_object = Auth.configuration.minute_class.constantize.new(minute_hash)

				incoming_minute_category_entity_type = 
							minute_object.get_category_entity_types

				minute = minute_object.minute
				
				
				minute_categories = minute_object.get_categories_to_capacity
				minute_consumables = minute_object.get_consumable_to_quantity 
				
				applicable_minute = nil

				if sorted_minutes.include? minute
					applicable_minute = minute
				else
					## iterate and the minute you find something less than this, black it out.
					sorted_minutes.each_with_index {|s,k|
						if s > minute
							if k > 0
								applicable_minute = sorted_minutes[k-1]
							end
							break
						end
					}
				end

				#puts "applicable minute is: #{applicable_minute}"
				next unless applicable_minute
				
				location_overlap_hash[applicable_minute.to_s.to_sym][:categories].keys.each do |k|
					
					## split the categories on "_"
					categories_in_this_key = location_overlap_hash[applicable_minute.to_s.to_sym][:categories][k][:category_names]


					puts "categories in this key: #{categories_in_this_key}"

					puts "categories searched for : #{categories_searched_for}"

					common_categories = categories_in_this_key & categories_searched_for

					puts "common categories :#{common_categories}"

					unless common_categories.empty?
						
						## does the minute hash i.e in the query result contain all the categories in the combination?
						minute_hash_contains_all_categories_in_this_key = categories_in_this_key & minute_categories.keys

						puts "minute hash contains all the categories in this key : #{minute_hash_contains_all_categories_in_this_key}"

						## if it does, then it means that this minute has to satisfy the requirements of this combination.
						if minute_hash_contains_all_categories_in_this_key.size == categories_in_this_key.size
								
							puts "size is equal."
							## the minute in the result, we want to get the hash of the categories to their entity types, with their capacities.
							

							puts "incoming entity types:" 
							puts incoming_minute_category_entity_type

							## now we will look which query ids from the overlap hash for the applicable minute are applicable to the current query id.

							## so this applicable query ids, should just return an array of the applicable query ids to this query id.

							if increment_by = applicable_query_ids(query_id,location_overlap_hash[applicable_minute.to_s.to_sym][:categories][k][:query_ids].keys)	

								puts "increment by is: #{increment_by}"

								## increment all the category requirements of the common categories by that much.
								
								## now we have to search inside those query ids, for the types
								## if we have the same types in any of the categories, then we have to go for it.
								## for each category, in the common categories, see if it is there in the 
								## we have to increment the type requirement incase it is the same type.
								common_categories.each do |cc|
									increment_by.each do |qid|




										location_overlap_hash[applicable_minute.to_s.to_sym][:categories][k][:query_ids][qid].keys.each do |cat|

											## so this is the category.
											if incoming_minute_category_entity_type[cat]

												location_overlap_hash[applicable_minute.to_s.to_sym][:categories][k][:query_ids][qid][cat].keys.each do |entity_type|

													puts incoming_minute_category_entity_type.to_s

													puts "cat is :#{cat}"
													puts "entity type is: #{entity_type}"

													## it is the same for consumables as well.
													if incoming_minute_category_entity_type[cat][entity_type]


														
														## the incoming minute has the same entity.
														## then we must add it to the requirements.

														## category_requirements will be incremented.
														if category_requirements[cat][entity_type]

															category_requirements[cat][entity_type] += location_overlap_hash[applicable_minute.to_s.to_sym][:categories][k][:query_ids][qid][cat][entity_type] 
														else
															category_requirements[cat][entity_type]
															category_requirements[cat][entity_type] = (location_overlap_hash[applicable_minute.to_s.to_sym][:categories][k][:query_ids][qid][cat][entity_type] + category_quantities[cat])
														end

													end

												end

											end	

										end
										
									end
								end

								## only whichever queries are applicable.
								## see what is already there in overlap hash, 
								consumables_searched_for.each do |consumable|

									## pick up for each of these from overlap hash, and create total combined requirements.
									if existing_in_overlap_hash = location_overlap_hash[applicable_minute.to_s.to_sym][:consumables][consumable.product_id]

										existing_in_overlap_hash.each do |defi|

											## if the query id is applicable, then increment the consumable minute_requirement
											if applicable_query_ids(query_id,[defi[:query_id]])

												consumable_requirements[consumable.product_id.to_s] += defi[:quantity]

											end

										end										

									end

								end

							end 

						end
					end


				end

				puts "category requirements are:"
				puts category_requirements.to_s

				category_requirements.keys.each do |cat|
					category_requirements[cat].keys.each do |type|

						indices_of_minutes_to_prune[location_index] << index if incoming_minute_category_entity_type[cat][type] < category_requirements[cat][type]


					end
				end


				consumable_requirements.keys.each do |c|

					indices_of_minutes_to_prune[location_index] << index unless (minute_consumables[c] >= consumable_requirements[c])

				end
				
			}

		}


		
	
		indices_of_minutes_to_prune.keys.each do |location_index|
			indices_of_minutes_to_prune[location_index].each do |min_index|
				query_result[location_index.to_i]["minutes"][min_index] = {}
			end
		end

		puts JSON.pretty_generate(query_result)

		puts "-- INDICES TO PRUNE -->"
		puts JSON.pretty_generate(indices_of_minutes_to_prune)

		## OKAY SO NOW WE WANT TO GIVE THE CAPACITY AVAILABLE IN THE MINUTE COMING IN TO BE LESS THAN WHATEVER WE CAN AFFORD.
		## 

		query_result

	end

	## THIS IS THE ONLY FUNCTION THAT IS TO BE CALLED.
	## @param[Array] query_result : A mongo aggregation result object, on which to_a has been called.
	## @param[Array] categories_searched_for : array of strings , the entity categories that were searched for.
	## @param[String] query_id : the id of the query, used in the filtering process.
	## @param[Array] consumables_searched_for : this is the array of consumable objects. Auth::Workflow::Consumable.
	def process_query_results(query_result,categories_searched_for,query_id,consumables_searched_for)
		## first we can do for categories , then for consumables ?
		## or simultaneously, simultaneously
		#query_result = filter_query_results(query_result,categories_searched_for,query_id,consumables_searched_for)
		#update_overlap_hash(query_result,categories_searched_for,query_id,consumables_searched_for)
	end

	#################### OVERLAP HASH FUNCTIONS END ######################


	## @return[Array] _branches : an array of branch addresses, where the items were added.
	def add_cart_items(cart_item_ids)
		_branches = []
		cart_item_ids.each do |cid|
			branch_located = false
			cart_item = Auth.configuration.cart_item_class.constantize.find(cid)
			self.levels.each do |level|
				level.branches.each do |branch|
					if branch.product_bunch == cart_item.bunch
						branch.input_object_ids << cid
						_branches << branch.address unless _branches.include? branch.address
						branch_located = true
					end
				end
			end
			raise "could not find a branch for #{cid}" unless branch_located
		end
		_branches 
	end


	def add_addresses
		_level = 0
		self.levels.each do |level|
			level.address = "l" + _level.to_s
			_branch = 0
			level.branches.each do |branch|
				branch.address = level.address + ":b" + _branch.to_s
				branch.definitions.each do |definition|
					_definition = 0
					definition.address = branch.address + ":d" + _definition.to_s
					_unit = 0
					definition.units.each do |unit|
						unit.address = definition.address + ":u" + _unit.to_s
						_unit+=1
					end
					_definition+=1
				end
				_branch+=1
			end
			_level+=1
		end	
	end


end