require 'rails_helper'

RSpec.describe Auth::Workflow::Sop, type: :model, :sop_model => true do

	context " -- create order flow -- " do 

		it " -- returns nil if no sop's are found -- " do 
			
			cart_items_and_assembly = create_cart_items_assembly_sops_with_product_ids(@u,2,false)
			cart_items = cart_items_and_assembly[:cart_items]
			assembly = cart_items_and_assembly[:assembly]
			## it should have created two cart items.
			## fire the clone event, expect it to return the array of events searching for those sop's.
			## now clone with all the product ids in the arguments.
			options = {}
			options[:product_ids] = cart_items.map{|c| c = c.product_id.to_s}
			events = assembly.clone_to_add_cart_items(options)
			## now for each of these events, we will have to process them.
			## how is this event processing going to work anyways?
			
		end

		it " -- creates a series of events to mark the requirements if sops's are found -- " do 


		end

	end

end