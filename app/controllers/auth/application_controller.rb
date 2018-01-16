module Auth
  class ApplicationController < ::ApplicationController
  	
    protect_from_forgery with: :exception
  	
    rescue_from ActionController::RoutingError do |e|
    	puts "e is : #{e.to_s}"
  		respond_to do |format|
	       format.json {render json: {:errors => e.to_s}, status: 422}
  		   format.js   {render :partial => "auth/modals/resource_errors.js.erb", locals: {:errors => [e.to_s]}}
	       format.html {render :text => e.to_s}
	    end
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


	 

  	

	 protected 

	 def check_method_missing
	 	puts Rails.application.routes.url_helpers.to_s
	 end

	 

  end
end
