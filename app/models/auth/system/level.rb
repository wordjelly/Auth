class Auth::System::Level

	include Auth::Concerns::SystemConcern
	embedded_in :wrapper, :class_name => "Auth::System::Wrapper"
	embeds_many :branches, :class_name => "Auth::System::Branch"

end