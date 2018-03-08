class Auth::Workflow::Requirement

	include Mongoid::Document
  	
  	include Auth::Concerns::OwnerConcern
  	
  	embedded_in :step, :class_name => Auth.configuration.step_class

    embeds_many :consumables, :class_name => Auth.configuration.consumable_class

    ## the maximum allowed value, after multiplying the base value
    field :max, type: Float, default: 1.0

    ## the minimum allowed value, after multiplying the base value
    field :min, type: Float, default: 0.0
    
    ## the base requirement amount for this requirement.
    field :base, type: Float, default: 1.0

    ## how much should the base be multiplied by  
    field :multiplicand, type: Float, default: 1.0

    ## base is multiplied by multiplicand only if product count is  >= this count.
    field :multiplicand_applied_at_product_count, type: Integer
    
    ## 0 => add validation error
    ## 1 => create a new consumable
    ## 2 => do nothing
    field :action_if_greater_than_max, type: Integer
    

    ## 0 => add validation error
    ## 1 => create a new consumable
    ## 2 => do nothing.
    field :action_if_greater_than_min, type: Integer

    ## structure:
    ## assembly_index => a
    ## stage_index => b
    ## sop_index => c
    ## step_index => d
    ## requirement_index => e
    ## this is something that cannot be modified, in the context of a users tests. 
    field :reference_requirement, type: Hash


    field :product_id, type: String

    def sufficient?(product_ids)  
     
      product_count = product_ids.size
      
      ## so we need a method on product, to check product stock, but it may be location dependent.

      if product_count >= multiplicand_applied_at_product_count

      end
    
    end


end