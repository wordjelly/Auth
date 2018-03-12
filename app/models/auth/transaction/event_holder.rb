class Auth::Transaction::EventHolder
	include Mongoid::Document

	## it will have an array of embedded event objects.
	## these objects will convey the last event that took place.
	## each event object will have its own attributes and data.
	embeds_many :events, :class => Auth::Transaction::Event


	## status, can be 0 -> processing/to_be_processed, or 1 -> completed.
	field :status, type: Integer
	validates :status, numericality: { only_integer: true, greater_than_or_equal_to: 0, less_than_or_equal_to: 1 }


	field :process_count, type: Integer
	validates :process_count, numericality: {only_integer: true}

	## this method is to be called on the event_holder object
	## it will take each event, and call the method defined in that event, and then proceed based on the after_complete option in that event.
	def process
		
		## return if the damn thing is processed.
		return if status == 1

		process_results = []	

		events.each do |event|
			new_events = event.process
			if new_events.nil?
				process_results << false
			else
				process_results << event.commit_output_events(self)
			end
		end

		## set the status to the process_results 
		status = process_results.uniq.size == 1 ? process_results.first : false


		Auth::Transaction::EventHolder.where({
			"$and" => [
				{
					"_id" => BSON::ObjectId(self.id.to_s)
				},
				{
					"status" => self.status_was
				}
			]
		}).find_one_and_update(
			{
				"$set" => {
					"status" => self.status
				},
				"$inc" => {
					"process_count" => 1
				}
			},
			{
				:return_document => :after
			}
		)

	end

end