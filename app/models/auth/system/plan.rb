class Auth::System::Plan
	include Mongoid::Document
	embedded_in :instant, :class_name => "Auth::System::Instant"
	field :start_time, type: Time
	field :end_time, type: Time
	field :entities, type: Array
	field :crawl_id, type: String
end