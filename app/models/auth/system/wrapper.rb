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
	def merge_minute_hash(existing,incoming)
		fused = existing.deep_dup
		
		[:categories_hash].each do |type|
			incoming[type].keys.each do |k|
				
				if fused[type][k]
					fused[type][k][:query_ids] << incoming[type][k][:query_ids][0]
				else 
					fused[type][k] = incoming[type][k]
				end
			end
		end

		incoming[:consumables_hash].keys.each do |product_id|
			## do we already have this product_id ?
			if fused[:consumables_hash][product_id]
				fused[:consumables_hash][product_id] << incoming[:consumables_hash][product_id]
			else
				fused[:consumables_hash][product_id] =  incoming[:consumables_hash][product_id]
			end
		end

		fused
	end

	## @param[Hash] minute_hash_to_insert : the query id and the categories for the minute we are wanting to insert. e.g : {categories_to_fuse.to_s => {:categories => [array_of_categories], query_ids => [query_id]}}
	## @param[Integer] minute : either the start or end_minute.
	## @param[String] location_id : the id of the location.
	## @return[nil]
	def manage_minute(minute_hash_to_insert,minute,location_id)
		
		location_id = location_id.to_sym

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
		location_id = location_id.to_sym

		existing_minutes = self.overlap_hash[location_id].keys.map{|c| c = c.to_s.to_i}.sort { |a, b| a <=> b }

		existing_minutes.each do |min|
			if ((min > start_minute) && (min < end_minute))
				self.overlap_hash[location_id][min.to_s.to_sym] = merge_minute_hash(self.overlap_hash[location_id][min.to_s.to_sym],minute_hash_to_insert)
			end
		end

	end

	## Updates the existing ranges in the overflow hash for this location id.
	## @param[Hash] start_minute_hash : the start_minute for the location id.
	## @param[Hash] end_minute_hash : the end_minute for the location id.
	## @param[String] location_id : the location_id from the query result.
	## @param[Array] categories_searched_for : the categories searched for in the query.
	## @param[String] query_id : the id of the query
	## @return[nil]
	def add_start_end_minute(start_minute,end_minute,location_id,categories_searched_for,query_id,consumables_searched_for)

		start_minute = start_minute_hash["minute"]
		end_minute = end_minute_hash["minute"]

		self.overlap_hash[location_id] = {} unless self.overlap_hash[location_id]

		## so here you have to add the consumables.
		## okay so suppose we added the consumables, now what happens next.

		## to insert it simultaneously , the minute to insert will be 
		## {:categories => {}, :consumables => {}}



		## and there it will be 
		## problem with this is no problem.
		c_hash = {}
		consumables_searched_for.each do |consumable_obj|
			c_hash[consumable_obj.product_id] = 
			[
				{
					:quantity => consumable_obj.quantity,
					:query_ids => [query_id] 
				}
			]
			## now when we add it, we just go on adding the quantity consumed by the query id.
		end


=begin
		##TO BE ADDED AFTER THE LOCATION SIDE OF IT IS READY.
		query_ids = {query_id.to_sym => {}}
		start_minute["categories"].each do |category|
			c = Auth::System::Category.new(category)
			## like [["type1",20],["type2",30]]
			query_ids[query_id.to_sym][c.category.to_sym] = c.get_types_for_overlap_hash 
		end
=end
		query_ids = [query_id]
		minute_to_insert = {
			:categories_hash => {
				categories_searched_for.join("_") => {:categories => categories_searched_for, :query_ids => query_ids}
			},
			:consumables_hash => c_hash
		}

		

		manage_minute(minute_to_insert,end_minute,location_id)

		manage_minute(minute_to_insert,start_minute,location_id)

		update_intervening_minutes(minute_to_insert,start_minute,end_minute,location_id)

	end

	## let me first test uptil here.


	## Adds the results of the query to the overlap hash, these results should be pre-filtered.
	## @param[Mongo::Aggregation] query_result : the result of the mongodb aggregation.
	## @param[Array] categories_searched_for : the categories_searched_for in the query.
	## @param[String] query_id : the arbitarily assigned id to the query.
	## @param[Array] consumables_searched_for : array of consumable objects.
	## @return[nil]
	def update_overlap_hash(query_result,categories_searched_for,query_id,consumables_searched_for)
		query_result.each do |location|
			
			location_id = location["_id"]
			start_minute = location["minutes"].first
			end_minute = location["minutes"].last
			
			if (start_minute && end_minute)
				add_start_end_minute(start_minute,end_minute,location_id,categories_searched_for,query_id,consumables_searched_for)
			end

		end
	end

	## @param[String] query_result_id : the id of the incoming query result.
	## @param[Array] category_combination_query_ids : the query_ids of the category_combination inside the applicable minute in the overflow hash.
	## @return[Array] applicable_query_ids : the number of query_ids that are applicable to overlap with this query_id. Returns nil if the array is empty.
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

	
	## fear is the key! RIP Alistair Mac'Lean	

	## @param[Mongo::Aggregation::Result] query_result : the result of the query.
	## @param[Array] categories_searched_for : an array of categories searched for.
	## @param[String] query_id : the string id of the query.
	## @param[Array] consumables_searched_for : Array of consumable objects.
	## @return[Hash] query_result : the query result after pruning it.
	## here comes the problematic part, for the manage requireemnts.
	def filter_query_results(query_result,categories_searched_for,query_id,consumables_searched_for)
		

		indices_of_minutes_to_prune = {}

		query_result.each_with_index {|location,location_index|
			
			indices_of_minutes_to_prune[location_index] = []

			location_overlap_hash = self.overlap_hash[location["_id"].to_sym]
			
			next unless location_overlap_hash

			sorted_minutes = location_overlap_hash.keys.map{|c| c = c.to_s.to_i}.sort { |a, b| a<=>b }

			location["minutes"].each_with_index{|minute_hash,index|

				category_requirements = categories_searched_for.map{|c| c = [c,1]}.to_h
				consumable_requirements = consumables_searched_for.map{|c| c = [c.product_id.to_s,c.quantity]}.to_h

				## the minute[Integer]
				minute = minute_hash["minute"]
				
				## the categories found in this minute.
				minute_categories = minute_hash["categories"].map{|c| c = [c["category"],c["capacity"]]}.to_h
				minute_consumables = minute_hash["consumables"].map{|c| c = [c["product_id"],c["quantity"]]}.to_h
				
				## a minute in the overlap hash that is either less than or equal to this minute
				applicable_minute = nil

				#puts "the minute coming in is: #{minute}"
				#puts "sorted minutes are: #{sorted_minutes}"
				## suppose a previous minute contains only the  

				## is there anything less than minute in sorted_minutes
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
				
				location_overlap_hash[applicable_minute.to_s.to_sym][:categories_hash].keys.each do |k|
					
					## split the categories on "_"
					categories_in_this_key = location_overlap_hash[applicable_minute.to_s.to_sym][:categories_hash][k][:categories]


					
					common_categories = categories_in_this_key & categories_searched_for

					
					unless common_categories.empty?
						
						## does the minute hash i.e in the query result contain all the categories in the combination?
						minute_hash_contains_all_categories_in_this_key = categories_in_this_key & minute_categories.keys

						## if it does, then it means that this minute has to satisfy the requirements of this combination.
						if minute_hash_contains_all_categories_in_this_key.size == categories_in_this_key.size
							
							## how many query ids are applicable from those in the overlap hash, to the current query id, at this combination?
							

							if increment_by = applicable_query_ids(query_id,location_overlap_hash[applicable_minute.to_s.to_sym][:categories_hash][k][:query_ids])

								## increment all the category requirements of the common categories by that much.
								#puts "these are the category requirements"
								#puts category_requirements.to_s
								#puts "increment by is: #{increment_by}"
								common_categories.each do |cc|
									category_requirements[cc]+=increment_by.size
								end

								## only whichever queries are applicable.
								## see what is already there in overlap hash, 
								consumables_searched_for.each do |consumable|

									## pick up for each of these from overlap hash, and create total combined requirements.
									if existing_in_overlap_hash = location_overlap_hash[applicable_minute.to_s.to_sym][:consumables_hash][consumable.product_id]

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

				category_requirements.keys.each do |s|

					indices_of_minutes_to_prune[location_index] << index unless (minute_categories[s] >= category_requirements[s])
				end


				consumable_requirements.keys.each do |c|

					indices_of_minutes_to_prune[location_index] << index unless (minute_consumables[c] >= consumable_requirements[c])

				end

				
			}

		}

		## okay so rather than pruning, this will have to be passed in as a part of the result.
		## and when we go to update the 
		#puts "minutes to prune are:"
		#puts JSON.pretty_generate(indices_of_minutes_to_prune)
		
		indices_of_minutes_to_prune.keys.each do |location_index|
			indices_of_minutes_to_prune[location_index].each do |min_index|
				query_result[location_index.to_i]["minutes"][min_index] = {}
			end
		end

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
		query_result = filter_query_results(query_result,categories_searched_for,query_id,consumables_searched_for)
		update_overlap_hash(query_result,categories_searched_for,query_id,consumables_searched_for)
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