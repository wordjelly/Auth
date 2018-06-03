class Auth::Work::Minute
	include Mongoid::Document
	embeds_many :cycles, :class_name => "Auth::Work::Cycle", :as => :minute_cycles
	field :time, type: Time
	field :geom, type: Array
end