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

	## take each event
	## if its complete , move forward
	## if its failed , return out of the function.
	## if its processing, return out of the function.
	## otherwise process the event
	## if the result is nil, 
	## if the result is not nil, commit and mark as complete the given event.
	## proceed, till end,now finally check event count, if not_equal, to start_count, means that many events, were added. exit out of function, without changing the status.
	## otherwise, set status as 1, where the status was not 1.
	def process
		
		return if status == 1

		abort_function = false

		events = get_events

		events.each_with_index {|ev,key|

			abort_function = true if (ev._processing? || ev._failed?)

			unless ev._completed?

				if events_to_commit = ev.process

					ev.event_index = key

					unless commit_new_events_and_mark_existing_event_as_complete(events_to_commit,ev)
						
						abort_function = true unless event_marked_complete_by_other_process?(ev)

					end
				else
					abort_function = true
				end
			end
		}

		return unless (events.count == get_events.count)

		return if abort_function == true


		self.status = 1


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

	def commit_new_events_and_mark_existing_event_as_complete(events,ev)


		doc_after_update = Auth::Transaction::EventHolder.where({
			"$and" => [
				{
					"_id" => BSON::ObjectId(self.id.to_s)
				},
				{
					"events.#{ev.event_index}._id" => BSON::ObjectId(ev)
				},
				{
					"events.#{ev.event_index}.statutes.#{ev.statuses.size - 1}.condition" => "PROCESSING"
				}
			]
		}).find_one_and_update(
			{
				## add to set all the events.
				## set the event status as completed.
				"$push" => {
					"events" => {
						"$each" => events.map{|c| c = c.attributes}
					},
					"events.#{ev.event_index}.statutes" => Auth::Transaction::Status.new(:condition => "COMPLETED", :created_at => Time.now, :modified_at => Time.now).attributes
				}
			},
			{
				:return_document => :after
			}
		)

		return doc_after_update

	end

	def event_marked_complete_by_other_process?(ev)
		## find a transaction event_holder with this id, where the event id is this events id, and the status of that event is completed.
		results = Auth::Transaction::EventHolder.collection.aggregate([
			{
				"$match" => {
					"_id" => BSON::ObjectId(self.id.to_s)
				}
			},
			{
				"$unwind" => {
					"path" => "$events"
				}
			},
			{
				"$unwind" => {
					"path" => "$events.statuses"
				}
			},
			{
				"$match" => {
					"$and" => [
						{
							"events.statuses._id" => BSON::ObjectId(ev.id.to_s)
						},
						{
							"events.statuses.condition" => "COMPLETED"
						}
					]
				}
			}
		])

		return true if results.count == 1

	end

	def get_events
		Auth::Transaction::EventHolder.find(self.id).events
	end

end