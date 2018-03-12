class Auth::Transaction::Status
	
	include Mongoid::Document
	include Mongoid::TimeStamps

	ALLOW_TO_CONTINUE_IN_SECONDS = 300

	field :condition, type: String
	embedded_in :event, :class => "Auth::Transaction::Event"
	
	def allow_to_continue?
		self.condition == "PROCESSING" && (Time.now.to_i - self.modified_at) < ALLOW_TO_CONTINUE_IN_SECONDS
	end

end