class Auth::Work::Link
	include Auth::Concerns::ChiefModelConcern
	embedded_in :instruction, :class_name => "Auth::Work::Instruction"
	field :url, type: String
	field :url_text, type: String
end	