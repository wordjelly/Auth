require "rails_helper"

RSpec.describe "Registration requests", :type => :request do
  before(:all) do 
    User.delete_all
    Auth::Client.delete_all
  end

  context "-- json request to callback phase" do 
 
  	it "-- works provided that state param is provided" do 

  	end

  end


	  

end