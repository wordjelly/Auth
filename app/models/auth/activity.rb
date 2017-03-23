module Auth
	class Activity
		include Mongoid::Document
		include Mongoid::Timestamps
		
		field :image_url, 			type: String, default: "/assets/auth/activity.jpg"

		##@param[Hash] range: {"from" => date[format: ], "to" => date[format: ]}
		##@return[Hash]: timestamp => activity_object hashified.
		def self.get_in_range(range)
			puts "came to get in range"
			puts "range from is: #{range[:from]}"
			puts "range to is: #{range[:to]}"
			activities = Auth::Activity.where(:created_at.gte => range["from"], :created_at.lte => range["to"])
			puts "activities size is: "
			puts activities.size
			puts "Activities entries are:"
			puts activities.entries.to_s
			activities_hash = Hash[activities.entries.map{|c| c.created_at.to_i}.zip(activities.entries.map{|c| c.as_json})]
			puts activities_hash.to_s
			return activities_hash
		end
		############################################################
		## Convenience functions, currently not used anywhere, just used once in rails console, to create 5 dummy activities.
		############################################################
		def self.rand_int(from, to)
		  Auth::Activity.rand_in_range(from, to).to_i
		end

		def self.rand_price(from, to)
		  Auth::Activity.rand_in_range(from, to).round(2)
		end

		def self.rand_time(from, to=Time.now)
		  Time.at(Auth::Activity.rand_in_range(from.to_f, to.to_f))
		end

		def self.rand_in_range(from, to)
		  rand * (to - from) + from
		end
		#############################################################
		## Convenience methods end here
		#############################################################

	end
end
