require "rails_helper"

RSpec.describe "Registration requests", :type => :request do
  before(:all) do 
    User.delete_all
    Auth::Client.delete_all
    @u = User.new(attributes_for(:user_confirmed))
    @u.save
    @c = Auth::Client.new(:resource_id => @u.id, :api_key => "test")
    @c.redirect_urls = ["http://www.google.com"]
    @c.app_ids << "test_app_id"
    @c.versioned_create
    @u.client_authentication["test_app_id"] = "test_es"
    @u.save
    @ap_key = @c.api_key

  end

  context "-- json request to callback phase" do 
 
  	it "-- works provided that state param is provided" do 
  		##so we want to simulate that the first step is carried out and
  		##we only do the callback to the server side api.
  		##the callback is the mock auth hash.
  		##so it should contain the additional state parameter.
  		
  	end

  end


	  

end