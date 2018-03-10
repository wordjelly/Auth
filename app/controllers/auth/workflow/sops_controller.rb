class Auth::Workflow::SopsController < Auth::Workflow::WorkflowController
  
  	## overridden to search for all those sop's which contain the applicable product_ids.
	def index
		puts "param are:"
		puts params.to_s
		puts "model params are:"
		puts @model_params.to_s
		puts "came to index."
		product_ids = @model.applicable_to_product_ids
		puts "the model is:"
		puts @model.attributes.to_s
		applicable_sops = @model.get_applicable_sops_given_product_ids
		## now it should return this array of hashes, as results.
		## but they have to be cast to array of sop models.
		## that will be a problem.
		
	end	

end