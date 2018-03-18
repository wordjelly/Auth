class Auth::Workflow::Requirement

	include Mongoid::Document
  	
  	include Auth::Concerns::OwnerConcern
  	
  	embedded_in :step, :class_name => Auth.configuration.step_class
    
    embeds_many :states, :class_name => Auth.configuration.state_class 
   
    field :reference_requirement, type: Hash

    ## the product id of the requirement.
    field :product_id, type: String

    ###########################################################
    ##
    ##
    ## set on calling sufficient.
    ##
    ##########################################################

    def calculate_required_states(orders)
      states.each do |state|
        state.calculate_required_states(orders)
      end
    end

    ## will be called in its own event.
    def mark_requirement

    end

end