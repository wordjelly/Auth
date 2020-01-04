class Auth::Work::Parameter
	include Mongoid::Document
	include Mongoid::Timestamps
	field :name, type: String
	embedded_in :product, :class_name => Auth.configuration.product_class
	field :choices, type: Array, default: []
	## for eg : if choices are numerical, and there are two of them, then they form the upper and lower limit.
	field :choices_are_limits, type: Boolean
end