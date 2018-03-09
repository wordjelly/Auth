class Auth::Workflow::SopsController < Auth::Workflow::WorkflowController
  
  	## overridden to search for all those sop's which contain the applicable product_ids.
	def index
		product_ids = @model.applicable_to_product_ids
		## now search for these, and return them in the projection.
		
	end	

end