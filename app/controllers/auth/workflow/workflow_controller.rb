class Auth::Workflow::WorkflowController < Auth::ApplicationController

	before_filter :instantiate_classes

	def instantiate_classes

		["assembly","stage","sop","step"].each do |workflow_component|

			if Auth.configuration.send("#{workflow_component}_class")

				begin
					self.send("@#{workflow_component}_class="Auth.configuration.send("#{workflow_component}_class").constantize)
				rescue
					not_found("could not instantiate class #{workflow_component}")
				end

			else
				not_found("#{workflow_component} class not defined in configuration")
			end

		end

	end

end