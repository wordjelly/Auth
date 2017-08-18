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

  def self.included(base)
    base.before(:each) { Warden.test_mode! }
    base.after(:each) { Warden.test_reset! }
  end

  def sign_in(resource)
    login_as(resource, scope: warden_scope(resource))
  end

  def sign_out(resource)
    logout(warden_scope(resource))
  end

  private

  def warden_scope(resource)
    resource.class.name.underscore.to_sym
  end

  def sign_in_as_a_valid_admin
    @admin = FactoryGirl.create :admin
    cli = Auth::Client.new
    cli.current_app_id = "test_app_id"
    @admin.set_client_authentication(cli)
    @admin.save!
    post_via_redirect admin_session_path, 'admin[email]' => @admin.email, 'admin[password]' => @admin.password
  end

  def sign_in_as_a_valid_and_confirmed_admin
    @admin = FactoryGirl.create :admin_confirmed
    cli = Auth::Client.new
    cli.current_app_id = "test_app_id"
    @admin.set_client_authentication(cli)
    @admin.save!
    post_via_redirect admin_session_path, 'admin[email]' => @admin.email, 'admin[password]' => @admin.password
  end
  
  # for use in request specs
  def sign_in_as_a_valid_user
    @user = FactoryGirl.create :user
    cli = Auth::Client.new
    cli.current_app_id = "test_app_id"
    @user.set_client_authentication(cli)
    @user.save!
    post_via_redirect user_session_path, 'user[email]' => @user.email, 'user[password]' => @user.password
  end

  def sign_in_as_a_valid_and_confirmed_user
    @user = User.new(attributes_for(:user_confirmed))
    cli = Auth::Client.new
    cli.current_app_id = "test_app_id"
    @user.set_client_authentication(cli)
    @user.save
    sign_in(@user)
  end


end

RSpec.configure do |config|
  config.include ValidUserHelper, :type => :controller
  config.include ValidUserRequestHelper, :type => :request
end