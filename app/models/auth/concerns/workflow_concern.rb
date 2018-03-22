module Auth::Concerns::WorkflowConcern

	extend ActiveSupport::Concern

	included do

		include Mongoid::Document
  		include Auth::Concerns::OwnerConcern

  		## the list of field names (strings) which are not changable if the assembly contains any orders.
  		field :fields_locked_after_adding_order, type: Array, default: []

  		## so how does this work exactly?
  		## if we are trying to update this object.
  		## let us have a method, where, these fields are removed from the shit passed in before doing the update building.

  		
  		def redact_locked_fields	

  		end


	end

end