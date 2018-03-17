class Auth::Workflow::State

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

	field :required_value, type: String

	field :setter_function, type: String, default: setter_function_default


	## will multiply the incoming value
	def setter_function_default
		"
			self.required_value = orders.size*self.multiplier_per_cart_item

			self.required_value = self.max_value if self.required_value > self.max_value

			self.required_value = self.min_value if self.required_value > self.min_value
		"
	end

	
	def calculate_required_state(orders)
		eval(setter_function)
	end


end