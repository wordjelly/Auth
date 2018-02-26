class Auth::Workflow::Step
	include Mongoid::Document
	embedded_in :sop, :class_name => "Auth::Workflow::Sop"
	field :name, type: String, default: nil
end

## if you change anything in a 