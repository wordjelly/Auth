class Auth::System::Merger

	include Mongoid::Document
	
=begin	
	10  =>  
	{
		query_id => {
			location => {
				minute_chain -> 
				start ->  
				end ->
			}
		}
	}
=end

	field :merger_hash, type: Hash, default: {}
	
	## the query result for a given query.
	## the query_id.
	def populate_merger_hash_for_the_first_time(query_result,query_id)

		query_result.each do |location|
				
			location_id = location["_id"].to_s
			
			minutes = location["minutes"]
			
			minutes = minutes.map{|c| c = Auth.configuration.minute_class.constantize.new(c)}
			
			minutes.each do |minute|
				
				min = minute.minute.to_s
				

				#puts "came to minute."
				self.merger_hash.deep_merge!({
					min.to_sym => {
						query_id.to_sym => {
							location_id.to_sym => {
								:combinations => {
									(location_id.to_s + "_" + min).to_sym => min 
								}
							}
						}
					}
				})

				
			end

		end

	end

	def query_result_to_hash(query_result)
		h = {}
		query_result.each_key do |location|
			location["minutes"].map{|c| c = c["minute"]}.each do |minute|
				build = {minute.to_sym => {}}
				location["applicable_to_locations"].each do |_id|
					build[minute_to_sym][_id] = true
				end
				h.deep_merge!(build)
			end
		end
		h
	end
	

	## @param[Array] query_result : the array of the query results.
	## @param[String] query_id : the query_id of the current query.
	## @param[String] target_query_id : an earlier query that you are targeting.
	## @param[Hash] location_applicability_hash : the hash which contains which location is applicable to which location
	## eg : {location_id_in_the_merger_hash => 
	## [indices_of_applicable_location_ids_from_the_result]
	## }
	def add_query_result(query_result,query_id,target_query_id,location_applicability_hash,min_addition,max_addition)

		query_result = query_result.to_a

		h = query_result_to_hash(query_result)
		range_start = h.keys[0] - min_addition
		range_end = h.keys[1] - max_addition

		query_id = query_id.to_sym
		target_query_id = target_query_id.to_sym
		location_applicability_hash.deep_symbolize_keys!

		## what is the range of applicable minutes?
		## first minute - minimum
		## last minute - maximum

		minutes_to_delete_for_query_id = []

		## at the end we have only 
		## okay its time to abort this, and finish the test object, guidelines, b2b, chat, ui frontend api, and video and image synchronization.
		## can i find a simplified solution for this ?
		## 
=begin
	## STRUCTURE OF COMBINATIONS TO INSERT : 
	{
		minute : {
			query_id : {
				location : {
					combinations : []
				}
			}
		}
	}
=end

		combinations_to_insert = {}

=begin
	{
		running_combinations : 
		{
				location_id : 
				[
					combination_one : closes_at_minute
					combination_two : closes_at_minute
				],
				location_id_2 :
				[
					combination_three : closes_at_minute
					combination_four : closes_at_minute
				]
		},
		combinations_to_close : {
			minute : {location_id => [combinations_ids..]}
		}

		## how to handle 
		## if a combination opens up, then we have to add it to this.
		## and if we encounter the minute where the combination closes, then we have to remove it at that time.
		## how to know we are iterating a combination ?
		## if that combination is encountered.
		## in the merger hash, at that minute, then it is open.
		## what will it have
		## for eg :
		## [1,2,3,4], and it will have a point where that combination closes.
		## so that minute will also be defined.
		## so how will the merger has look at a particular location at a particular minute ? 
		## it just has a hash of combinations.
		## and where it ends.
		## thats; all.
		## so let us give it a key, like 
	}
=end
			open_combinations_hash = {
				:running_combinations => {}
			}


			## how does it work
			## take the result
			## take each minute
			## merger hash get minutes applicable
			## if minute has query id
			## check if it has any of the locations, otherwise delete it.
			## if it has, then check if applicable, otherwise move on
			## rebuild the query result first
			## get it by minute.
			## we actually just want the minutes
			## and the locations.
			## nothing else.
			## that can be easily done


			self.merger_hash.each_key do |minute|
				
				## everytime you do a new minute, clear the open_combinations hsh.
				open_combinations_hash = {:running_combinations => {}}
				if merger_hash[minute].key? target_query_id
					merger_hash[minute][target_query_id].each_key do |location_id|
						if location_applicability_hash.key? location_id
							## add open combinations.
							if combinations_hash = merger_hash[minute][target_query_id][location_id][:combinations]

								open_combinations_hash[:running_combinations][location_id] = {} unless open_combinations_hash[:running_combinations][location_id]

								combinations_hash.each_key do |combination|
									open_combinations_hash[:running_combinations][location_id][combination] = combinations_hash[combination]
								
								end

							end

							## close the open combinations that no longer apply.
							## where do we close the combinations ?
							## exactly ?
							## when are combinations no longer applicable ?
							## 

							## now comes the part where we actually write forward.
							## these values, 
							location_applicability_hash[location_id].each do |index_in_result|
								## here we need only the first and last minute.
								## here we need the first minute within range.
								## and also the last minute.
								start_search = minute.to_s.to_i + min_addition
								end_search = minute.to_s.to_i + max_addition
								start_minute = nil
								end_minute = nil
								

								location_id_of_result_location = query_result[index_in_result]["_id"]

								
								query_result[index_in_result]["minutes"].each do |result_minute|

									puts "start search is: #{start_search}"
									puts "end search is  : #{end_search}"
									puts "root minute is :#{minute}"
									puts "start minute is: #{start_minute}"
									puts "end minute is: #{end_minute}"
									puts "Result minute is:"
									puts result_minute["minute"]
									puts "------------------------------"
									## why does 1 -> 218?

									if ((result_minute["minute"] >= start_search) && (result_minute["minute"] <= end_search))
										if start_minute.nil?
											start_minute = result_minute["minute"]
										else
											end_minute = result_minute["minute"]
										end
									else
										## TODO : test this.
										break
									end
								end
								
								puts "open combination hash is:"
								puts JSON.pretty_generate(open_combinations_hash)

								## if we only have a start minute, then the end minute equals to it.
								end_minute = start_minute unless end_minute

								if start_minute && end_minute
									puts "start minute: #{start_minute} and end_minute: #{end_minute}:"

									open_combinations_hash[:running_combinations][location_id].each_key do |combi|

										combinations_to_insert = combinations_to_insert.deep_merge({
											start_minute.to_s.to_sym =>
											{
												query_id.to_sym => {
													 location_id_of_result_location.to_s.to_sym => {
													 	:combinations => {
													 		(combi.to_s + "_" + location_id_of_result_location.to_s + "_" + start_minute.to_s).to_sym => end_minute
													 	}
													 }
												}
											}
										})

										puts "after merging it becomes:"
										puts JSON.pretty_generate(combinations_to_insert)

									end
								end
							end
						end 
					end
				else
					#puts "target query id is not a key of this minute."
				end
			end
		
		#puts "the combinations to insert are:"
		#puts JSON.pretty_generate(combinations_to_insert)
		self.merger_hash = self.merger_hash.deep_merge(combinations_to_insert)

		

	end



end