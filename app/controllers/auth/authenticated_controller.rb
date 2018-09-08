class Auth::AuthenticatedController < Auth::ApplicationController

	
	include Auth::Concerns::DeviseConcern
	include Auth::Concerns::TokenConcern

	
	CONDITIONS_FOR_TOKEN_AUTH = [:create,:update,:destroy,:edit,:new,:index]
	TCONDITIONS = {:only => CONDITIONS_FOR_TOKEN_AUTH}
	before_filter :do_before_request , TCONDITIONS
	before_filter :instantiate_classes
	before_filter :build_model_from_params 
	## add the filters for check_for_create, check_for_update and check_for_destroy
	before_filter(:only => [:create]){|c| check_for_create(@model)}
	before_filter(:only => [:update]){|c|  check_for_update(@model)}
	before_filter(:only => [:destroy]){|c|  check_for_destroy(@model)}




	


	

	###########################################################
	##
	##
	## controller route actions
	##
	##
	###########################################################

	# GET /auth/assemblies
	def index
	    @models = @model.get_many
	    respond_to do |format|
	      format.json do 
	        render json: @models.to_json
	      end
	      format.html do 
	      	render :index
	      end
	    end
	end

	# GET /auth/assemblies/1
	def show
	    respond_to do |format|
	      format.json do 
	        render json: @model.to_json
	      end
	    end
	end

	# GET /auth/assemblies/new
  	def new
    	#@auth_assembly = Auth::Assembly.new
  	end

	# GET /auth/assemblies/1/edit
	def edit
	end

	# POST /auth/assemblies
 	def create

 		## so how to create an assemly
 		## there is no difference.

 		## how to create a stage
 		## we need to know the assembly version
 		## and find one and update, where id is that and its version is that.

 		## we can specify those conditions on the model.
 		## for example we can have a method called model_create
 		## and return the model from that.

	    respond_to do |format|
	        if @model.create_with_conditions(params,@model_params,@model)
	            format.json do 
	                render json: @model.to_json, status: 201
	            end
	            format.html do 
	                render :show
	            end
	            format.text do 
	                render :text => @model.text_representation 
	            end
	            format.js do 
	                render :partial => "show.js.erb", locals:{model: @model}
	            end
	        else
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

	# PATCH/PUT /auth/assemblies/1
  	def update
	    respond_to do |format|
	      	if @model.update_with_conditions(params,@model_params,@model)
	        	format.json do 
	          		render :nothing => true, :status => 204
	        	end
	        	format.js do 
	        		render :partial => "show.js.erb", locals: {model: @model}
	        	end
	        	format.html do 
	        		render :show
	        	end
	      	else
	        	format.json do 
	          		render json: {
	            		id: @model.id.to_s,
	            		errors: @model.errors
	          		}.to_json, status: 422
	        	end
	        	format.js do 
	        		render :partial => "show.js.erb", locals: {model: @model}
	        	end
	        	format.html do 
	        		render :show
	        	end
	      	end
	    end
  	end

	# DELETE /auth/assemblies/1
	def destroy
	    respond_to do |format|
	      if @model.destroy
	        format.json do 
	          render :nothing => true, :status => 204
	        end
	        format.js do 
	        	render 'destroy'
	        end
	      else
	        format.json do 
	          render json: {
	            id: @model.id.to_s,
	            errors: @model.errors
	          }.to_json
	        end
	        format.js do 
	        	render 'destroy'
	        end
	      end
	    end
	end

	private
	
  	def permitted_params    
    	params.permit(@model_class.permitted_params)
  	end

end