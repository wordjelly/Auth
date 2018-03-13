class Auth::Transaction::EventHolder
	include Mongoid::Document

	## it will have an array of embedded event objects.
	## these objects will convey the last event that took place.
	## each event object will have its own attributes and data.
	embeds_many :events, :class_name => "Auth::Transaction::Event"


	## status, can be 0 -> processing/to_be_processed, or 1 -> completed.
	field :status, type: Integer
	validates :status, numericality: { only_integer: true, greater_than_or_equal_to: 0, less_than_or_equal_to: 1 }, :allow_nil => true


	field :process_count, type: Integer, default: 0
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

			puts "processing event"
			puts ev.attributes.to_s

			ev.event_index = key

			if (ev._processing? || ev._failed?)
				puts "processing or failed."
				abort_function = true 
				break
			end

			unless ev._completed?
				puts "not completed."

				unless ev_updated = mark_event_as_processing(ev)
					abort_function = true 
					break
				end
				
				ev_updated.event_index = key


				if events_to_commit = ev_updated.process

					unless ev_updated = commit_new_events_and_mark_existing_event_as_complete(events_to_commit,ev_updated)
						
						unless event_marked_complete_by_other_process?(ev_updated)
							abort_function = true 
							break
						end

					end
				else
					abort_function = true
					break
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

		## get the latest event_holder

		## if the last event is this event -> go and push all the new events, where the last event id is this.

		## if the result is nil, check again if the event count is increased, then someone else did it.

		## else there is a failure.

		## if the last event is not this event, then go ahead and check if this events index is completed ?

		## otherwise go to complete it where not completed.

		qr = {
			"$and" => [
				{
					"_id" => BSON::ObjectId(self.id.to_s)
				},
				{
					"events.#{ev.event_index}._id" => BSON::ObjectId(ev.id.to_s)
				},
				{
					"events.#{ev.event_index}.statutes" => {
						"$size" => ev.statuses.size
					}
				}
			]
		}

		## only way to do this is to set the whole events array again.

		## but if that array is huge?

		## doesnt matter much ?

		## or do two seperate updates.

		puts "the commit new event query result count is:"
		qrs = Auth::Transaction::EventHolder.where(qr).count
		puts qrs
		doc_after_update = Auth::Transaction::EventHolder.where(qr).find_one_and_update(
			{
				## add to set all the events.
				## set the event status as completed.
				"$push" => {
					"events" => {
						"$each" => events.map{|c| c = c.attributes}
					}
				},
				"$set" => {
					"events.#{ev.event_index}.statuses" => (ev.statuses.map{|c| c = c.attributes})
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


	## @param[Event] 
	def mark_event_as_processing(ev)
		puts "came to mark event as processing."
		

		or_query = [
						{
						"events.#{ev.event_index}.statuses.0" => 
							{
							"$exists" => false
							}
						}
					]

		if ev.statuses.size > 0
			
			## want to make sure that the size  is nil.
			## and the size - 1 is processing.
			## that way you can get the last one.
			## otherwise you fail.
			## and its no longer an or query.

			or_query << {
							"events.#{ev.event_index}.statuses.#{ev.statuses.size - 1}.condition" => "PROCESSING"
						}
		end

		
		qr = {
			"$and" => [
				{
					"_id" => BSON::ObjectId(self.id.to_s)
				},
				{
					"events.#{ev.event_index}._id" => BSON::ObjectId(ev.id.to_s)
				},
				{
					"$or" => or_query
				}
			]
		}

		
		doc_after_update = Auth::Transaction::EventHolder.where(qr).find_one_and_update(
			{
					"$push" => {
						"events.#{ev.event_index}.statuses" => Auth::Transaction::Status.new(:condition => "COMPLETED", :created_at => Time.now, :updated_at => Time.now).attributes
					}
			},
			{
					:return_document => :after
			}
		)
		return nil unless doc_after_update
		return doc_after_update.events[ev.event_index]
	end

	def get_events
		Auth::Transaction::EventHolder.find(self.id).events
	end

end