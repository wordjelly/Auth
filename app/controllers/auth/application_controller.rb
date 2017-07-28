module Auth
  class ApplicationController < ::ApplicationController
  	
    protect_from_forgery with: :exception
  	
  
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

	 ##CURRENTLY BEING USED IN THE DUMMY APP IN ITS USERS/CONFIRMATIONS_CONTROLLER
	 ##RENDERS A NOT FOUND RESPONSE, in case the user is not found.
	 def not_found
	 	  raise ActionController::RoutingError.new('Not Found')
	 end


	 

  	

	 protected 

	 def check_method_missing
	 	puts Rails.application.routes.url_helpers.to_s
	 end

	 

  end
end
