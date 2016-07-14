require "rails_helper"


describe Auth::ClientsController do 


	context "-- client web app ---" do 

		it "-- should create a client ---" do

			c = Auth::Client.new
			c.redirect_urls = ["hello"]
			@params = c.attributes	
			post :create, @params 
			#response = assigns(:r)
			#params_should_equal_response(response,@params,subject.current_user)
			#Corner.count.should eq(1)

		end

	end


end