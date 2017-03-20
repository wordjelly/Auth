module Auth
	class Activity
		include Mongoid::Document
		include Mongoid::Timestamps
		
		field :image_url, 			type: String, default: "/assets/auth/activity.jpg"

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

	end
end
