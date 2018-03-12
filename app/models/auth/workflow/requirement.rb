class Auth::Workflow::Requirement

	include Mongoid::Document
  	
  	include Auth::Concerns::OwnerConcern
  	
  	embedded_in :step, :class_name => Auth.configuration.step_class
    
    ## the maximum allowed value, after multiplying the base value
    field :max, type: Float, default: 1.0

    ## the minimum allowed value, after multiplying the base value
    field :min, type: Float, default: 0.0
    
    ## the base requirement amount for this requirement.
    field :base, type: Float, default: 1.0

    ## how much should the base be multiplied by  
    field :multiplicand, type: Float, default: 1.0


    ## divide the products by the multiplicand_applied_at_product_count.
    ## so if 6 products, and add consumable is 4, then we will have 2 consumables.
    field :products_per_consumable, type: Integer
    
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

    ## the product id of the requirement.
    field :product_id, type: String

    def sufficient?(product_ids)  
     
      product_count = product_ids.size

      consumables_count = consumables_required(product_count)

      ## now do we already have a reference_requirement_id ?
      if reference_requirement
        ## check if there are enough requirements, otherwise, 
      else

      end
    
    end

    ## @param[Integer] product_count : the number of products for which we are checking this requirement.
    ## @return[Integer] the number of consumables required, for this requirement to service the product count incoming.
    def consumables_required(product_count)
      modulus = product_count % products_per_consumable

      modulus+=1 if modulus > 0

      modulus
    end

    ## get the reference requirement.
    def get_reference_requirement
      ## so we need to get the reference requirement.
      ## and see if its consumables fit the bill.
      ## to do this, we need the assembly id.
      ## and that entire reference.
      ## 
    end

end