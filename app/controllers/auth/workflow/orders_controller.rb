class Auth::Workflow::OrdersController < Auth::Workflow::WorkflowController
  
  	def create
  		@model.errors.add(:_id,"orders cannot be directly created.")
  		respond_to do |format|
	        format.json do 
	            render json: {
	              id: @model.id.to_s,
	              errors: @model.errors
	            }.to_json, status: 422
	        end
	        format.html do 
	            render :new
	        end
	        format.js do 
	            render :partial => "show.js.erb", locals:{model: @model}
	        end
	    end

  	end	
	
end