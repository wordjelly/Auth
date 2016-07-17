require "rails_helper"

RSpec.describe "New user creation", :type => :request do

  it "creates a new user" do
   
    
    post user_registration_path, :user => attributes_for(:user)
    @user = assigns(:user)
    expect(@user.es).not_to be_nil
    expect(@user.authentication_token).not_to be_nil
  end

  
end