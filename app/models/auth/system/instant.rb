class Auth::System::Instant

	include Mongoid::Document

	embeds_many :collectors, :class_name => "Auth::System::Collector"
	embeds_many :plans, :class_name => "Auth::System::Plan"

	## it can have a product count
	field :product_count, type: Integer

	## it will have a product id.
	field :product_id, type: String

	## the location data for this thing.
	field :geom, type: Array
	

	def self.build_instants(start_date,end_date,product_ids)
		product_ids.each do |product_id|
			begin
				product = Auth.configuration.product_class.constantize.find(product_id)

				product.max_at_any_instant.times do |product_count|

					## so the first step is to pass a fictional product count to the products

					## we will have to iterate wherever that entity was being used in those minutes -> there it will have to 
					## this could become hundreds of thousands of updates
					## that doesnt make sense
					## actually
					## ideally we should only be booking that entity.
					## and later on doing some kind of join.
					## so suppose i search for just the capacity
					## for some minute brackets, for those capacities, they get taken
					## if you only want to update the minute based schedules when something changes, then 


				end


			rescue Mongoid::Errors::DocumentNotFound

			end 
		end 
	end



end	