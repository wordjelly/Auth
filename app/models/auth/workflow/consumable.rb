class Auth::Workflow::Consumable
	include Mongoid::Document
	embedded_in :minute, :class_name => Auth.configuration.minute_class
	field :product_id, type: String
	field :quantity, type: Float
	attr_accessor :minute_requirement
end