class Auth::Work::Bullet
	include Mongoid::Document
	embedded_in :instruction, :class_name => "Auth::Work::Instruction"
	field :text, type: String
	## it will have an image, but that will come later on.
end