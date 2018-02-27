class Auth::Workflow::WorkflowController < Auth::ApplicationController

	CONDITIONS_FOR_TOKEN_AUTH = [:create,:update,:destroy,:edit,:new,:index]
	TCONDITIONS = {:only => CONDITIONS_FOR_TOKEN_AUTH}
	include Auth::Concerns::DeviseConcern
	include Auth::Concerns::TokenConcern
	before_filter :do_before_request , TCONDITIONS
	before_filter :instantiate_classes
	before_filter :build_model_from_params 
	before_filter :is_admin_user , :only => CONDITIONS_FOR_TOKEN_AUTH


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
      	@model = permitted_params[:id] ? @model_class.find_self(permitted_params[:id],current_signed_in_resource) : @model_class.new(permitted_params[get_model_class_name.to_sym])
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
	    @models = @model_class.all
	    respond_to do |format|
	      format.json do 
	        render json: @models.to_json
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
		## how do i know for eg:
		## which stage, to push the sop into
		## so i need to get that shit out of somewhere.

		save_response = false

		if @model.class == "Assembly"
			save_response = @model.save
		else
			if @model.valid?
				## we need to get the position of all this shit.
				## run an elemmatch query to first get the position of the stage
				## then another to get the position of the sop
				## then query
				@model = Auth.configuration.assembly_class.constantize.where
				({
					"$and" => 
					[
						{
							"doc_version" => @model.assembly_doc_version
						},
						{
							"_id" => BSON::ObjectId(@model.assembly_id)
						}
					]
				}).find_one_and_update(
					{
						"$push" => 
							{
								:stages => @model.attributes 
							}
					},
					{
						:return_document => :after
					}
				)
				save_response = false unless @model
			end
		end

	    respond_to do |format|
	      if @model.save
	        format.json do 
	          render json: @model.to_json, status: 201
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

	# PATCH/PUT /auth/assemblies/1
  	def update

	    respond_to do |format|
	      if @model.save
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