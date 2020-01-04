class Auth::Work::Link
	include Mongoid::Document
	include Mongoid::Timestamps
	include Auth::Concerns::ImageLoadConcern
	embedded_in :instruction, :class_name => "Auth::Work::Instruction"
	field :url, type: String
	field :url_text, type: String
end	