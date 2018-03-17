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




    def sufficient?(orders)  
      

      ## now do we already have a reference_requirement_id ?
      if reference_requirement
          
        ## in this case return its state
        ## what should be the required state of that the reference requirement?
        ## how to calculate that
        ## given orders.

      else

        product_ids = orders.map{|c| c = c.cart_item_ids}.flatten

        product_count = product_ids.size

        #self.consumables_count = consumables_required(product_count)

        ##its basically going to return a consumable count.

      end
    
    end

    ## @param[Integer] product_count : the number of products for which we are checking this requirement.
    ## @return[Integer] the number of consumables required, for this requirement to service the product count incoming.
    def consumables_required(product_count)
      #modulus = product_count % products_per_consumable

      #modulus+=1 if modulus > 0

      #modulus
    end


    ## given the orders, what should be the state of this requirement.
    ## this will be called by the requirment, inside which the id of the reference requirement is stored.
    ## so the former requirement will call this method on another requirement.
    ## and this method should return the required state, of this requirement.(i.e the reference_requirement.)
    def reference_requirement_necessary_state(orders)
      ## so this can be stuff like
      ## expected liquid amount
      ## expected minimum
      ## expected maximum
      ## can we have a programmable way to do this?
      ## for eg given number of orders
      ## we can define key value pairs
      ## key -> order
      ## can the value be a function of some kind.
      ## for eg imagine a cook has a to make something 
      ## and he needs that depending on number of cutlets,
      ## the temperature of the cooking oil should be 300 degrees.
      ## so we can just have a simple multiple.
      ## we can also have some reserve keys like "consumables"
      ## this will return the count of consumables.
      ## eg : 1 -> for every 4 products.
      ## but if its not a consumable.
      ## suppose we want
      ## this is becoming unnecessarily complicated.
    end 

end