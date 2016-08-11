module Auth
  class ApplicationController < ActionController::Base
  	
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

	

  end
end
