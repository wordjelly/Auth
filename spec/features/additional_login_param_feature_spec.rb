#additional_login_param_feature_spec.rb
require "rails_helper"

RSpec.feature "additional login param + its redirect", :type => :feature, :js => true  do

  before(:each) do 
 	    ActionController::Base.allow_forgery_protection = true
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


  context " -- does otp sign up -- " do 



  end
  
end