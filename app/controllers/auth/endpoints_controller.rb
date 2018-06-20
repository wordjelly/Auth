class Auth::EndpointsController < Auth::ApplicationController

	## responds only to json.
	## got to add the thing to subscribe them to a topic as well.

	include Auth::Concerns::DeviseConcern
	
	CONDITIONS_FOR_TOKEN_AUTH = [:create,:update,:destroy,:edit,:new,:index]
	TCONDITIONS = {:only => CONDITIONS_FOR_TOKEN_AUTH}
	before_filter :do_before_request , TCONDITIONS
	before_filter :instantiate_classes
	before_filter :build_model_from_params 
	before_filter(:only => [:create]){|c| check_for_create(@model)}		

	## all i have to do now is set the routes
	## and this should start saving endpoints automatically as needed.
	## so now lets try to make a new endpoint.
	## question is that what if that token already exists ?
	## so i will do a find_one_and_update.

	def create
		or_clause = []
		
		or_clause << {
			"android_token" => self.android_token
		} if self.android_token
		
		or_clause << {
			"ios_token" => self.ios_token
		} if self.ios_token

		returned_document = @model.class.where({
			"$or" => or_clause
		}).find_one_and_update(
			{
				"$set" => self.attributes,

			},
			{
				:return_document => :after
			}
		)

		#respond_to do |format|
	    #   format.json {render json: returned_document.to_json, status: returned_document}
	    #end

	end

	def permitted_params
		params.require(:endpoint).permit(:android_token,:ios_token)
	end

end