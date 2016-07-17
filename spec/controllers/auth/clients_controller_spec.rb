require "rails_helper"

##if you want to test a controller that uses routes defined by the 
describe Auth::ClientsController do 

	def main_app
  		Rails.application.class.routes.url_helpers
	end

	routes{Auth::Engine.routes}

	

	context "-- no authentication headers ---" do

			context " -- web app requests -- " do 

				it "-- get request should not proceed -- " do 

					get :index
					expect( response ).to redirect_to( main_app.new_user_session_path )

				end

				it "--- post request should not proceed --- " do 

					client = attributes_for(:client)
					post :create, :params => client
					expect( response ).to redirect_to( main_app.new_user_session_path )
				end

			end

			context " -- json api request --- " do 

				it " -- get request should produce 401 -- " do 

					get :index, :format => :json
					expect( response.status ).to be(401)

				end

				it " -- post request should produce 401 -- " do 

					post :create, :params => attributes_for(:client), :format => :json
					expect( response.status ).to be(401)

				end

			end

	end


	context " -- incorrect authentication headers --- " do 

			before(:each) do 
				@request.headers["X-User-Token"] = "wrong"
 				@request.headers["X-User-Es"] = "wrong"
			end
				
			context " -- web app requests -- " do 

				it "-- get request should not proceed -- " do 

					get :index, nil
					expect( response ).to redirect_to( main_app.new_user_session_path )

				end

				it "--- post request should not proceed --- " do 

					client = attributes_for(:client)
					post :create, client
					expect( response ).to redirect_to( main_app.new_user_session_path )
				end

			end

			context " -- json api request --- " do 
				before(:each) do 
					@request.headers["HTTP_ACCEPT"] = "application/json"
 					@request.headers["CONTENT_TYPE"] = "application/json"
				end
				
				it " -- get request should produce 401 -- " do 
					
					get :index
					expect( response.status ).to be(401)

				end

				it " -- post request should produce 401 -- " do 

					post :create, attributes_for(:client)
					
					expect( response.status ).to be(401)

				end

			end			

	end

	context " -- correct authentication headers --- " do 

		before(:context) do 
			@useri = User.new(attributes_for(:user))
			##@useri.skip_confirmation!
			@useri.es = "trachoma"
			@useri.authentication_token = "pallidum"
			@useri.save
			
		end

		

		context "--- it should proceed --- " do 

			context " -- web app requests -- " do 

				it "-- get request should not proceed -- " do 
					@request.headers["X-User-Token"] = @useri.authentication_token
 					@request.headers["X-User-Es"] = @useri.es
					get :index
					expect( response.status ).to be(200)

				end

				

			end


		end

	end

end


