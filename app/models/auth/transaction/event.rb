class Auth::Transaction::Event
	
	include Mongoid::Document
	include Mongoid::Timestamps

	embedded_in :event_holder, :class_name => "Auth::Transaction::EventHolder"
	embeds_many :statuses, :class_name => "Auth::Transaction::Status"

	attr_accessor :event_index

	## 0. ( basically will move on to the next event in the event holder.)
	## 1. commit output_events (it will create all the output events.)
	field :after_complete, type: Integer, default: 0

	## validate numericality and range, between 0 and 1.
	validates :after_complete, numericality: { only_integer: true, greater_than_or_equal_to: 0, less_than_or_equal_to: 1 }

	## array of hashes of event objects
	## like : [{method, object_class, object_id, arguments:},{method, object_class, object_id, arguments:}]
	## these should be committed into the event at the same t
	field :output_events, type: Array, default: []


	## were the output events committed ?
	## so that we don't do it twice :)
	field :output_events_committed, type: Boolean

	## the method that has to be called on the object class
	field :method_to_call, type: String
	validates :method_to_call, presence: true 

	## the object class to instantiate the object id from.
	field :object_class, type: String
	validates :object_class, presence: true


	## id of the object.
	## should be a valid bson::objectid
	field :object_id, type: String

	validate do |event|
		
		if event.object_id
			errors.add(:object_id,"the object id must be a valid bson object id") unless BSON::ObjectId.legal?(event.object_id)
		end
		
	end


	## arguments is an array of hashes.
	## the method has to know what to do with them.
	field :arguments, type: Hash

	## @return[Array] array of Auth::Transaction::Event objects.
	## or nil, in case the #object_id of this event cannot be found.
	def process
		if self.object_id
			return nil unless get_object
			#puts "the get object is:"
			#puts get_object.to_s
			self.output_events = get_object.send(method_to_call,arguments)
		else
			self.output_events = self.object_class.constantize.send(method_to_call,arguments)
		end
		self.output_events
	end

	## here we will have a problem with nested objects.
	## and will have to provide a better way to query this.
	def get_object
		begin
			self.object_class.constantize.find(object_id)
		rescue Mongoid::Errors::DocumentNotFound
			puts "could not find the document."
			nil
		end
	end

	def _completed?
		statuses.last && statuses.last.is_complete?
	end

	def _processing?
		statuses.last && statuses.last.is_processing?
	end

	def _failed?
		statuses.last && statuses.last.is_failed?
	end

end