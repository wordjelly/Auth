require "rails_helper"

##if you want to test a controller that uses routes defined by the 
describe Auth::ClientsController do 
	routes{Auth::Engine.routes}

	context "-- client web app ---" do 

		it "-- should create a client ---" do

			c = Auth::Client.new
			c.redirect_urls = ["hello"]
			@params = {:client => c.attributes}	
			post :create, @params 
			

		end

	end

end


