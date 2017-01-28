#module for helping controller specs
module ValidUserHelper
  def signed_in_as_a_valid_user
    @user ||= FactoryGirl.create :user
    sign_in @user # method from devise:TestHelpers
  end

  def signed_in_as_a_valid_admin
    @admin ||= FactoryGirl.create :admin
    sign_in @admin
  end
end

# module for helping request specs
module ValidUserRequestHelper
  include Warden::Test::Helpers

  def sign_in_as_a_valid_admin
    @admin = FactoryGirl.create :admin
    @admin.set_client_authentication("test_app_id")
    @admin.save!
    post_via_redirect admin_session_path, 'admin[email]' => @admin.email, 'admin[password]' => @admin.password
  end

  def sign_in_as_a_valid_and_confirmed_admin
    @admin = FactoryGirl.create :admin_confirmed
    @admin.set_client_authentication("test_app_id")
    @admin.save!
    post_via_redirect admin_session_path, 'admin[email]' => @admin.email, 'admin[password]' => @admin.password
  end
  
  # for use in request specs
  def sign_in_as_a_valid_user
    @user = FactoryGirl.create :user
    @user.set_client_authentication("test_app_id")
    @user.save!
    post_via_redirect user_session_path, 'user[email]' => @user.email, 'user[password]' => @user.password
  end

  def sign_in_as_a_valid_and_confirmed_user
    @user = FactoryGirl.create :user_confirmed
    ##should call set_client_authentication.
    ##with the app id used throughout.
    @user.set_client_authentication("test_app_id")
    @user.save!
    post_via_redirect user_session_path, 'user[email]' => @user.email, 'user[password]' => @user.password
  end


end

RSpec.configure do |config|
  config.include ValidUserHelper, :type => :controller
  config.include ValidUserRequestHelper, :type => :request
end