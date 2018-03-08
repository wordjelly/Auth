class Auth::Workflow::Requirement
	include Mongoid::Document
  	include Auth::Concerns::OwnerConcern
  	embedded_in :step, :class_name => Auth.configuration.step_class
end