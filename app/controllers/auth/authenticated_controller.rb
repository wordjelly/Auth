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




	## @return[String] model_name : given a controller with name AssembliesController -> will return assembly
	## will downcase and singularize the controller name.
	def get_model_class_name
		
		class_name = nil

		self.class.name.scan(/::(?<plural_controller_name>[A-Za-z]+)Controller$/) do |ll|

			jj = Regexp.last_match
			
			plural_controller_name = jj[:plural_controller_name]

			class_name = plural_controller_name.singularize.downcase

		end

		not_found("could not determine class name") unless class_name
		
		

		return class_name
	
	end

	def instantiate_classes

		if Auth.configuration.send("#{get_model_class_name}_class")

			begin
				instance_variable_set("@model_class",Auth.configuration.send("#{get_model_class_name}_class").constantize)
			rescue 
				not_found("could not instantiate class #{get_model_class_name}")
			end

		else
			not_found("#{get_model_class_name} class not defined in configuration")
		end

	end


	def build_model_from_params
      	pp = permitted_params
      	puts "the permitted_params are:"
      	puts permitted_params.to_s

      	@model_params = pp.fetch(get_model_class_name.to_sym,{})
      	@model = pp[:id] ?  @model_class.find_self(pp[:id],current_signed_in_resource) : @model_class.new(@model_params)
	end


	

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
	      else
	        format.json do 
	          render json: {
	            id: @model.id.to_s,
	            errors: @model.errors
	          }.to_json
	        end
	      end
	    end
	end

	private
	
  	def permitted_params    
    	params.permit(@model_class.permitted_params)
  	end

end