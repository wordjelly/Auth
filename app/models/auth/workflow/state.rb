class Auth::Workflow::State

	include Mongoid::Document

	embedded_in :requirement, :class_name => Auth.configuration.requirement_class

	## array of permitted values

	## min value, max value

	## function to set required state, which accepts the orders as input

	## current_value.

	field :permitted_values, type: Array

	field :multiplier_per_cart_item, type: Float

	field :min_value, type: Float

	field :max_value, type: Float

	field :current_value, type: String

	attr_accessor :required_value

	def self.setter_function_default
		"
			self.required_value = orders.size
		"
	end

	field :setter_function, type: String, default: setter_function_default


	
	

	## @param[Array] array of order objects
	## @return[nil] just sets the required_value of this state.
	def calculate_required_state(orders)
		eval(setter_function)
	end



end