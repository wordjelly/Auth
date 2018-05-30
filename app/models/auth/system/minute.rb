class Auth::System::Minute
	include Mongoid::Document
	field :minute, type: Integer
	field :geom, type: Array
	embeds_many :entities, :class_name => "Auth::System::Entity"
end