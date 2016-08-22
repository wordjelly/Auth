require "rails_helper"
=begin
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

				before(:example) do 
					controller.class.skip_before_filter :ensure_json_request
				end

				after(:example) do 
					controller.class.prepend_before_filter :ensure_json_request

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

			before(:example) do 
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

			before(:example) do 
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

		before(:example) do 
			@user = User.new(attributes_for(:user))
			@user.es = "trachoma"
			@user.authentication_token = "pallidum"
			@user.save
			@request.headers["X-User-Token"] = @user.authentication_token
	 		@request.headers["X-User-Es"] = @user.es
			@request.headers["HTTP_ACCEPT"] = "application/json"
 			@request.headers["CONTENT_TYPE"] = "application/json"
		end

		it " -- get request is successfull -- " do
			get :index
			expect(response.status).to be(200)
		end

		it " -- does not update if client does not exist -- " do 
			c = Auth::Client.new(:redirect_urls => ["http://www.google.com"])
			c.user_id = BSON::ObjectId.new
			put :update, :id => c.user_id, :client => c.attributes
			client = assigns(:client)
			expect(response.status).to be(404)
			expect(client).to be(nil)
		end

		it " -- updates if urls are valid, with status code 204 -- " do 
			c = Auth::Client.new(:redirect_urls => ["http://www.google.com"])
			c.user_id = @user.id
			put :update, :id => c.user_id, :client => c.attributes
			client = assigns(:client)
			expect(response.status).to be(204)
			expect(client.op_success?).to be(true)
		end

		it " -- update fails, with invalid url, with code 422 --- " do 
			##we give some invalid urls and get the errors.
			c = Auth::Client.new(:redirect_urls => ["dog"])
			c.user_id = @user.id
			put :update, :id => c.user_id, :client => c.attributes
			client = assigns(:client)
			expect(client.errors.full_messages).not_to be_empty
			expect(response.status).to be(422)
		end

		it " -- destroys if client exists with 204 -- " do

			c = Auth::Client.new
			c.user_id = @user.id 
			delete :destroy, :id => c.user_id
			expect(response.status).to be(204)
			destroyed = Auth::Client.where(:id => c.user_id)
			expect(destroyed.count).to be(0)

		end

		it " -- shows the client if it exists, with 200 --- " do 

			c = Auth::Client.new
			c.user_id = @user.id
			get :show, :id => c.user_id
			client = assigns(:client)
			expect(response.status).to be(200)
			expect(client.user_id.to_s).to eq(c.user_id.to_s)

		end


	end



end

=end
