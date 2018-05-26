class Merger

	include Mongoid::Document
	

	field :merger_hash, type: Hash, default: {}

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

	## later i want to directly find something applicable to this query id.
	## and this location.
	## with a start and end 
	## i think this should be pretty fast.


=end

	def add_query_result(query_result,query_id,target_query_id = nil,target_location_ids=nil)

		## i need to transpose this result.
		## it should be like
		## suppose the merger hash has a minute
		## and an entity id.
		## if that is not target ignore.

		if target_query_id
			## we can iterate only the merger hash minutes at one time.
			## if the target location id is 
			merger_hash.each_key do |minute|
				if minute.key? target_query_id
					## combine the locations and the combinations.
					## dont make it seperate, flatten it to a simple hash combining the location and the combination
					## okay so what do we have to do exactly.
					## get the locations from the result that are applicable to the location herein.
					## then for each such applicable location in the result
					## get the first and last minute that is applicable to this minute
					## inside that first and last minute, add this location_minute as a combination
					## keep a running hash of all the location_minute combinations that are open, since a minute may not have a combination registered on it, as it is the intervening minute.
					## and in this way, go on adding the combinations.
					## finally will have the necessary results.
					## and we will have to iterate the merger hash only once.
				end
			end
		else
			query_result.each do |location|
				
				location_id = location["_id"].to_s
				
				minutes = location["minutes"]
				
				minutes = minutes.map{|c| c = Auth.configuration.minute_class.constantize.new(c)}
				
				minutes.each do |minute|
					
					min = minute.minute
					
					merger_hash[min.to_sym] = {} unless merger_hash[min.to_sym]
					
					merger_hash[min.to_sym][query_id.to_sym] = {} unless merger_hash[min.to_sym][query_id.to_sym]
					
					merger_hash[min.to_sym][query_id.to_sym][location_id.to_sym] = {
							:minute_chain => [min],
							:chain_length => 1
							:start => nil,
							:end => nil
						} unless merger_hash[min.to_sym][query_id.to_sym][location_id.to_sym]
					
				end

			end

		end

	end



end