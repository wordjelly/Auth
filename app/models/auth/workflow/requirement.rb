class Auth::Workflow::Requirement

	include Mongoid::Document
  	
  	include Auth::Concerns::OwnerConcern
  	
  	embedded_in :step, :class_name => Auth.configuration.step_class

  	## for each key in the hash -> it has to define how the number will affect it
  	## any key suffixed with
  	## eg;
  	## so suppose you pass in 3 products
  	## it will first say ok
  	## so multiply base_color by color factor
  	## then if > max_color -> see what to do when exceeds one.
  	## if < max_color -> see what to do when less than one
  	## so how to define that?
  	##{
	  	##  max_volume :
	  	##  min_volume :
	  	##  base_volume :  
	  	##  color_factor : {can be defined per/ product or per/ n products.}
	  	##  factor_exceeds_one : [fail/create_new/discard] 
	  	##  factor_falls_short_of_one : [fail/discard]
	##}
  	field :state, type: Hash, default: {}

  	## now what about the output?
  	## who will store the output state?
  	## this consists of the count and condition of each item of this requirement.
  	## suppose we have to create 3 such items, then what will be the way of tagging them and keeping track of them?
  	## what are they going to be called
  	## which object?
  	## so we can create subobjects
  	## call them pieces
  	## eventually while matching you will have to query them.
  	## and that's where the cookie will crumble
  	## so let us have a another object for this.
  	field :output_state, type: Hash, default: {}

end