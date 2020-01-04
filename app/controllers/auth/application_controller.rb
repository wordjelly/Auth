module Auth
  class ApplicationController < ::ApplicationController
  	
    protect_from_forgery with: :exception
  	
    rescue_from ActionController::RoutingError do |e|
    	puts "e is : #{e.to_s}"
  		respond_to do |format|
	       format.json {render json: {:errors => e.to_s}, status: 422}
  		   format.js   {render :partial => "auth/modals/resource_errors.js.erb", locals: {:errors => [e.to_s]}}
	       format.html {render :plain => e.to_s.html_safe}
	    end
  	end  

  	rescue_from ActionController::UnknownFormat do |e|
  		render status: 404, text: "Not Found"
  	end


  	######################################################################
  	##
  	##
  	## METHODS USED ON AUTHENTICATED_CONTROLLER, and some other controllers.
  	##
  	##
  	######################################################################

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
		
		puts "class name: #{class_name}"
		

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
		#puts "params are: #{params.to_s}"
      	pp = permitted_params
      	#puts "the permitted_params are:"
      	#puts permitted_params.to_s

      	@model_params = pp.fetch(get_model_class_name.to_sym,{})
      	#puts "model params are:"
      	#puts @model_params.to_s

      	@model = pp[:id] ?  @model_class.find_self(pp[:id],current_signed_in_resource) : @model_class.new(@model_params)

	end


    def from_bson(bson_doc,klass)

	 	if !bson_doc.nil?

	 		user = Mongoid::Factory.from_db(klass,bson_doc)
	 		return user

	 	else

	 		return nil

	 	end

 	end

 	def from_view(view,klass)

	 	if !view.nil? && view.count > 0

	 		user = Mongoid::Factory.from_db(klass,view.first)
	 		return user

	 	else

	 		return nil

	 	end

	 end

	 ##CURRENTLY BEING USED IN THE DUMMY APP IN OTP_CONTROLLER
	 ##RENDERS A NOT FOUND RESPONSE, in case the user is not found.
	 ##
	 def not_found(error = 'Not Found')
	 	  raise ActionController::RoutingError.new(error)
	 end


	 
	def check_for_update(obj)
		puts "Came to check for update."
		not_found if obj.nil?
    	not_found("please provide a valid id for the update") if obj.new_record?
	end

	def check_for_create(obj)
		not_found if obj.nil?
		obj.new_record? or not_found("this is not a new record")
	end
  	
	def check_for_destroy(obj)
		not_found("please provide a cart id") if obj.new_record?
	end

	## will call authenticate_(first_key_in_the_auth_resources) if there is no currently signed in scoep
	## will return true, for the first auth_resource that gives a current_(user/whatever)
	## if nothing returns true, will redirect to not_found,
	## use this function wherever you want to protect a controller just using devise authentication.
	## only makes sense to use in the scope of the web app.
	def authenticate_resource!
  		send("authenticate_#{Auth.configuration.auth_resources.keys.first.downcase}!") if (signed_in? == false)
  		Auth.configuration.auth_resources.keys.each do |model|
  			break if @resource_for_web_app = send("current_#{model.downcase}")
  		end
  		return if @resource_for_web_app
  		not_found("Could not authenticate")
  	end



  	

	 protected 

	 def check_method_missing
	 	puts Rails.application.routes.url_helpers.to_s
	 end

  end
end
