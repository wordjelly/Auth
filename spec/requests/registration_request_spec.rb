require "rails_helper"

RSpec.describe "New user creation", :type => :request do

  #it "creates a new user" do 
  #  post user_registration_path, :user => attributes_for(:user)
  #  @user = assigns(:user)
  #  expect(@user.es).not_to be_nil
  #  expect(@user.authentication_token).not_to be_nil
  #end

  context " -- web app requests -- " do 




  end


  context " -- json requests -- " do 
  	##so we will have to prepend before filters.
  	##how to do this, without fucking up the devise controller creation.
  	##we will have to add something in the the application level
  	##so basically now what?
  	##so basically we modify the traditional before hooks.
  	



  end
  
end