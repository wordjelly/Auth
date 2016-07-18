require "rails_helper"

##if you want to test a controller that uses routes defined by the 
describe Auth::ClientsController do 

	def main_app
  		Rails.application.class.routes.url_helpers
	end

	routes{Auth::Engine.routes}

	context " -- ENFORCES JSON REQUESTS -- " do 

		context " -- non json requests -- " do 

			context " -- keeping the ensure_json_request_filter --- " do 

				it " -- should return a 406 code -- " do 

					get :index
					expect(response.status).to be(406)

				end

				it " -- should return 406 even provided correct auth headers -- " do 

					@user = User.new(attributes_for(:user))
					@user.save
					@request.headers["X-User-Token"] = @user.authentication_token
		 			@request.headers["X-User-Es"] = @user.es
					get :index
					expect(response.status).to be(406)

				end

			end

			context " -- skipping the ensure json request filter --- " do 

				before(:each) do 
					controller.class.skip_before_filter :ensure_json_request
				end

				it " -- should return a 302 code -- " do 

					get :index
					expect(response.status).to be(302)

				end

				it " -- should return 200  -- " do 

					@user = User.new(attributes_for(:user))
					@user.save
					@request.headers["X-User-Token"] = @user.authentication_token
		 			@request.headers["X-User-Es"] = @user.es
					get :index
					expect(response.status).to be(200)

				end

			end

		end

		context " -- json requests -- " do 

			before(:each) do 
				@request.headers["HTTP_ACCEPT"] = "application/json"
 				@request.headers["CONTENT_TYPE"] = "application/json"
			end

			it " -- should return a 401 not-authenticated code -- " do 

				get :index
				expect(response.status).to be(401)

			end

			it " -- should return 200  -- " do 

				@user = User.new(attributes_for(:user))
				@user.save
				@request.headers["X-User-Token"] = @user.authentication_token
	 			@request.headers["X-User-Es"] = @user.es
				get :index
				expect(response.status).to be(200)

			end

		end

	end


	context "-- no authentication headers ---" do


			it " -- get request should produce 401 -- " do 

				get :index, :format => :json
				expect( response.status ).to be(401)

			end

			it " -- post request should produce 401 -- " do 

				post :create, :params => attributes_for(:client), :format => :json
				expect( response.status ).to be(401)

			end

		
	end


	context " -- incorrect authentication headers --- " do 

			before(:each) do 
				@request.headers["X-User-Token"] = "wrong"
 				@request.headers["X-User-Es"] = "wrong"
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

	context " -- correct authentication headers --- " do 

		before(:each) do 
			@user = User.new(attributes_for(:user))
			@user.es = "trachoma"
			@user.authentication_token = "pallidum"
			@user.save
			@request.headers["X-User-Token"] = @user.authentication_token
	 		@request.headers["X-User-Es"] = @user.es
		end

		it " -- get request is successfull -- " do 
			get :index
			expect(response.status).to be(200)
		end

		it " -- vaidates the urls before updating --- " do 
			##we give some invalid urls and get the errors.
			c = Auth::Client.new(:redirect_urls => ["dog"])
			c.user_id = @user.id
			#post :update, :params => c.attributes
			put :update, :id => c.user_id, :client => c.attributes
			client = assigns(:client)
			puts client.errors.full_messages.to_s
			expect(client.errors.full_messages).not_to be_empty

		end


	end



end


