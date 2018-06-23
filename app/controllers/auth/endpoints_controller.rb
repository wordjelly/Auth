class Auth::EndpointsController < Auth::ApplicationController

	## responds only to json.
	## got to add the thing to subscribe them to a topic as well.
	respond_to :json

	include Auth::Concerns::DeviseConcern
	
	CONDITIONS_FOR_TOKEN_AUTH = [:create,:update,:destroy,:edit,:new,:index]
	TCONDITIONS = {:only => CONDITIONS_FOR_TOKEN_AUTH}
	before_filter :do_before_request , TCONDITIONS
	before_filter :instantiate_classes
	before_filter :build_model_from_params 
	before_filter(:only => [:create]){|c| check_for_create(@model)}		

	def create

		
		or_clause = []
		
		or_clause << {
			"android_token" => @model.android_token
		} if @model.android_token
		
		or_clause << {
			"ios_token" => @model.ios_token
		} if @model.ios_token

		if or_clause.empty?
			returned_document = nil
		else
			returned_document = @model.class.where({
				"$or" => or_clause
			}).find_one_and_update(
				{
					"$setOnInsert" => @model.attributes,

				},
				{
					:upsert => true,
	 				:return_document => :after
				}
			)

			if returned_document
				returned_document.set_android_endpoint
				returned_document.set_ios_endpoint
			end

		end

		respond_to do |format|
			if returned_document
				format.json do 
					render json: returned_document.to_json, status: 201
				end
			else
				format.json do 
					render json: {
		            }.to_json, status: 422
	        	end
			end
		end

	end

	def permitted_params
		params.permit({:endpoint => [:android_token,:ios_token]},:api_key,:current_app_id)
	end

end