class Auth::Work::Minute
	include Mongoid::Document
	embeds_many :cycles, :class_name => "Auth::Work::Cycle", :as => :minute_cycles
	field :minute, type: Integer
	field :geom, type: Array
end