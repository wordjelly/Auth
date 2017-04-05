module Auth
	class Activity
		include Mongoid::Document
		include Mongoid::Timestamps

		field :user_id, 			type: BSON::ObjectId
		field :image_url, 			type: String, default: "/assets/auth/activity.jpg"

		##@param[Hash] {"range" : {"from" : unix_epoch_as_string, "to" => unix_epoch_as_string}, "user_id": string}
		##@return[Hash]: timestamp => activity_object hashified.
		def self.get_in_range(params)
			activities = Auth::Activity.where(:created_at.gte => params[:range][:from].to_i, :created_at.lte => params[:range][:to].to_i, :user_id => params[:user_id])			
			activities_hash = Hash[activities.entries.map{|c| c.created_at.to_i}.zip(activities.entries.map{|c| c.as_json})]
			puts JSON.pretty_generate(activities_hash)
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

		##Deletes all existing activities and users in the database
		##creates 5 activities created by one user and 5 activities created by another user. 
		def self.create_random_activities
			puts "deleting all existing users:" + User.delete_all.to_s
			puts "deleting all existing activities:" + Auth::Activity.delete_all.to_s
			puts "creating two fake users"
			u = User.new
			u.email = "hello@gmail.com"
			u.password = "password"
			u.confirm!
			puts "saving first user:" + u.save.to_s
			u1 = User.new
			u1.email = "goodbye@gmail.com"
			u1.password = "password"
			u1.confirm!
			puts "saving second user:" + u1.save.to_s
			5.times do |n|
				a = Auth::Activity.new
				a.created_at = Auth::Activity.rand_time(n.days.ago)
				a.user_id = u.id
				puts "Created activity #{n} with user 1:" + a.save.to_s
			end

			5.times do |n|
				a = Auth::Activity.new
				a.created_at = Auth::Activity.rand_time(n.days.ago)
				a.user_id = u1.id
				puts "Created activity #{n} with user 2:" + a.save.to_s
			end

		end
		#############################################################
		## Convenience methods end here
		#############################################################

	end
end
