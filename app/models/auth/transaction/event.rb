class Auth::Transaction::Event
	
	include Mongoid::Document
	include Mongoid::TimeStamps

	embedded_in :event_holder, :class => "Auth::Transaction::EventHolder"
	embeds_many :statuses, :class => "Auth::Transaction::Status"

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
		
		errors.add(:object_id,"the object id must be a valid bson object id") unless BSON::ObjectId.legal?(event.object_id)
		
	end


	## arguments is an array of hashes.
	## the method has to know what to do with them.
	field :arguments, type: Array

	## @return[Array] array of Auth::Transaction::Event objects.
	## or nil, in case the #object_id of this event cannot be found.
	def process
		nil unless get_object
		self.output_events = get_object.send(method_to_call,arguments)
		self.output_events
		## ideally commit these events if any, and simultaneously push the status of the current event as completed.
	end

	def get_object
		begin
			self.object_class.constantize.find(object_id)
		rescue Mongoid::Errors::DocumentNotFound
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