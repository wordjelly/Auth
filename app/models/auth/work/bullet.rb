class Auth::Work::Bullet
	include Mongoid::Document
	include Mongoid::Timestamps
	include Auth::Concerns::ImageLoadConcern
	
	embedded_in :instruction, :class_name => "Auth::Work::Instruction"
	field :title, type: String
	field :description, type: String
	field :text, type: String
end