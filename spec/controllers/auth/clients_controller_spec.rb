require "rails_helper"

##if you want to test a controller that uses routes defined by the 
describe Auth::ClientsController do 
	routes{Auth::Engine.routes}

	context "-- client web app ---" do 

		context "-- no authentication headers ---" do


			it "-- should return not authenticated http response code -- " do 

				get :index
				expect(response).to have_http_status(401)
				#expect( response ).to redirect_to( new_user_session_path )
				#c = Auth::Client.new
				#c.user_id = BSON::ObjectId.new
				#c.redirect_urls = ["hello"]
				#@params = {:client => c.attributes}	
				#post :create, @params 

			end

		end

	end

end


