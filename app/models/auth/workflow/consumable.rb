class Auth::Workflow::Consumable

	include Mongoid::Document
  	
  	include Auth::Concerns::OwnerConcern

	embedded_in :requirement, :class_name => Auth.configuration.requirement_class	  	

	field :existing_consumable_id, type: String

	
	field :input_state, type: Hash

	
	field :output_state, type: Hash


	field :product_id, type: String

	
	validates_presence_of :product_id

end

