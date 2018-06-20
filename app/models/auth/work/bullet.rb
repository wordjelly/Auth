class Auth::Work::Bullet
	include Mongoid::Document
	include Auth::Concerns::ChiefModelConcern
	embedded_in :instruction, :class_name => "Auth::Work::Instruction"
	field :title, type: String
	field :description, type: String
	field :text, type: String
end