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
					"combination_of_categories" : [query_ids....]
			},
			"minute_range_end" : {
					"combination_of_categories" : [query_ids...]
			}
		}
	}
=end

	field :overlap_hash, type: Hash, default: {}

		
	## @param[Hash] existing : the existing hash at the minute.
	## @param[Hash] incoming : the incoming hash that we want to merge, this will be with just one key. e.g : {categories_to_fuse.to_s => {:categories => [array_of_categories], query_ids => [query_id]}}
	## @return[Hash] existing : after merging in the incoming hash.
	def merge_minute_hash(existing,incoming)
		incoming.keys.each do |k|
			existing[k][:query_ids] << incoming[k][:query_ids][0] if existing[k]
			existing[k] = incoming[k]
		end
		existing
	end

	## @param[Hash] minute_hash_to_insert : the query id and the categories for the minute we are wanting to insert. e.g : {categories_to_fuse.to_s => {:categories => [array_of_categories], query_ids => [query_id]}}
	## @param[Integer] minute : either the start or end_minute.
	## @return[nil]
	def manage_minute(minute_hash_to_insert,minute)

		existing_minutes = self.overflow_hash[location_id].keys.sort { |a, b| a <=> b }

		less_than_minute = existing_minutes.bsearch{|c| c < minute}

		equal_to_minute = existing_minutes.bsearch{|c| c == minute}

		greater_than_minute = existing_minutes.bsearch{|c| c > minute}


		## suppose there is an equal to , then we have to fuse it with that.
		## **(minute).............
		if equal_to_minute 
			self.overflow_hash[location_id][minute] =  merge_minute_hash(self.overflow_hash[location_id][minute],minute_hash_to_insert)
		
		else

			## only less than or only greater than, and equal to is nil.
			## **..........(minute) || (minute)............**
			if ((less_than_minute && greater_than_minute.nil?) || (less_than_minute.nil? && greater_than_minute))
				self.overflow_hash[location_id][minute] = minute_to_insert 
			end

			## less than and greater than, and equal to is nil
			## **................(minute)...............**
			if greater_than_minute && less_than_minute
				## in this case we want to fuse in the less than minute with this one and add it in.
				fused_hash = merge_minute_hash(self.overflow_hash[location_id][less_than_minute],minute_hash_to_insert)
				self.overflow_hash[location_id][minute] = fused_hash
			end

		end

		## there is one more possibility where there is nothing else.
		## in that case, we have to add the start and end minute direct.


	end

	## finds all the minutes in between the newly inserted start and end minute, and fuses the minute_hash into them.
	## @param[Hash] minute_hash_to_insert : the query id and the categories for the minute we are wanting to insert. e.g : {categories_to_fuse.to_s => {:categories => [array_of_categories], query_ids => [query_id]}}
	## @param[Integer] start_minute : the start_minute for the location_id.
	## @param[Integer] end_minute : the end_minute for the location_id.
	## @return[nil]
	def update_intervening_minutes(minute_hash_to_insert,start_minute,end_minute)

		existing_minutes = self.overflow_hash[location_id].keys.sort { |a, b| a <=> b }

		existing_minutes.each do |min|
			if ((min > start_minute) && (min < end_minute))
				self.overflow_hash[location_id][min] = merge_minute_hash(self.overflow_hash[location_id][min],minute_hash_to_insert)
			end
		end

	end

	## Updates the existing ranges in the overflow hash for this location id.
	## @param[Integer] start_minute : the start_minute for the location id.
	## @param[Integer] end_minute : the end_minute for the location id.
	## @param[String] location_id : the location_id from the query result.
	## @param[Array] categories_searched_for : the categories searched for in the query.
	## @param[String] query_id : the id of the query
	## @return[nil]
	def add_start_end_minute(start_minute,end_minute,location_id,categories_searched_for,query_id)

		self.overflow_hash[location_id] = {} unless self.overlap_hash[location_id]

		minute_to_insert = {categories_searched_for.join("_") => {:categories => categories_searched_for, :query_ids => [query_id]}}

		manage_minute(minute_to_insert,end_minute)

		manage_minute(minute_to_insert,start_minute)

		update_intervening_minutes(minute_to_insert,start_minute,end_minute)

	end

	## Adds the results of the query to the overlap hash, these results should be pre-filtered.
	## @param[Mongo::Aggregation] query_result : the result of the mongodb aggregation.
	## @param[Array] categories_searched_for : the categories_searched_for in the query.
	## @param[String] query_id : the arbitarily assigned id to the query.
	## @return[nil]
	def update_overlap_hash(query_result,categories_searched_for,query_id)
		query_result.each do |location|
			start_minute = location["minutes"].first["minute"]
			end_minute = location["minutes"].last["minute"]
			location_id = location["_id"]
			add_start_end_minute(start_minute,end_minute,location_id,categories_searched_for,query_id)
		end
	end

	## @param[String] query_result_id : the id of the incoming query result.
	## @param[Array] category_combination_query_ids : the query_ids of the category_combination inside the applicable minute in the overflow hash.
	## @return[Array] applicable_query_ids : the number of query_ids that are applicable to overlap with this query_id. Returns nil if the array is empty.
	def applicable_query_ids(query_result_id,category_combination_query_ids)

		return nil

	end

=begin
@eg : 
=end

	## @param[Mongo::Aggregation::Result] query_result : the result of the query.
	## @param[Array] categories_searched_for : an array of categories searched for.
	## @param[String] query_id : the string id of the query.
	## @return[Hash] query_result : the query result after pruning it.
	def filter_query_results(query_result,categories_searched_for,query_id)

		indices_of_minutes_to_prune = {}

		query_result.each_with_index {|location,location_index|
			
			indices_of_minutes_to_prune[location_index] = []

			location_overflow_hash = self.overflow_hash[location["_id"]]
			
			sorted_minutes = location_overflow_hash.keys.sort { |a, b| a<=>b }

			location["minutes"].each_with_index{|minute_hash,index|

				category_requirements = categories_searched_for.map{|c| c = [c,1]}.to_h

				## the minute[Integer]
				minute = minute_hash["minute"]
				
				## the categories found in this minute.
				minute_categories = minute_hash["categories"].map{|c| c = [c["category"],c["capacity"]]}.to_h
				
				## a minute in the overlap hash that is either less than or equal to this minute
				applicable_minute = sorted_minutes.bsearch{|c| c <= minute}

				## iterating each category combination in the applicable overlap hash minute.
				applicable_minute.keys.each do |k|
					
					## split the categories on "_"
					categories_in_this_key = k.split("_")
					
					## are there any categories in common with what we searched ?
					common_categories = categories_in_this_key & categories_searched_for
					
					unless common_categories.empty?
						
						## does the minute hash i.e in the query result contain all the categories in the combination?
						minute_hash_contains_all_categories_in_this_key = categories_in_this_key & minute_categories.keys
						
						## if it does, then it means that this minute has to satisfy the requirements of this combination.
						if minute_hash_contains_all_categories_in_this_key.size == categories_in_this_key.size
							
							## how many query ids are applicable from those in the overlap hash, to the current query id, at this combination?
							if increment_by = applicable_query_ids(applicable_minute[k][:query_ids],query_id)

								## increment all the category requirements of the common categories by that much.
								common_categories.each do |cc|
									category_requirements[cc]+=increment_by
								end

							end 

						end
					end
				end

				category_requirements.keys.each do |s|

					## iterate the categories, 

					indices_of_minutes_to_prune[location_index] << index unless (minute_hash["categories"][s] >= category_requirements[s])
				end
				
			}

			## now prune that.
		}

		indices_of_minutes_to_prune.keys.each do |location_index|
			indices_of_minutes_to_prune[location_index].each do |min_index|
				query_result[location_index][min_index] = {}
			end
		end

		query_result

	end

	## THIS IS THE ONLY FUNCTION THAT IS TO BE CALLED.
	def process_query_results(query_result,categories_searched_for,query_id)
		query_result = filter_query_results(query_result,categories_searched_for)
		update_overlap_hash(query_result,categories_searched_for,query_id)
	end

	## first will have to write the tests for making the actual queries.
	## then the test for filtering it through the overflow_hash
	## then populating the overflow hash.
	## then passing forward of the last minute/location id : those tests.

	## so i have four hours, will attempt to do first test in 

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