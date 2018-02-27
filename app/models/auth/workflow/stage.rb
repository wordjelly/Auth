class Auth::Workflow::Stage
	include Mongoid::Document
	embeds_many :sops, :class_name => "Auth::Workflow::Sop"
	embedded_in :assembly, :class_name => "Auth::Workflow::Assembly"
	field :name, type: String
end
