class Auth::Transaction::Status
	
	include Mongoid::Document
	include Mongoid::Timestamps

	ALLOW_TO_CONTINUE_IN_SECONDS = 300

	## "PROCESSING"
	## "COMPLETE"
	## "FAILED"
	field :condition, type: String
	embedded_in :event, :class_name => "Auth::Transaction::Event"
	

	def is_complete?
		self.condition == "COMPLETE"
	end

	def is_processing?
		self.condition == "PROCESSING" && (Time.now.to_i - self.modified_at) < ALLOW_TO_CONTINUE_IN_SECONDS
	end

	def is_failed?
		self.condition == "FAILED" 
	end

end