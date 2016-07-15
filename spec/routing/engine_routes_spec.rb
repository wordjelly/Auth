require "rails_helper"
=begin
RSpec.describe Auth::RegistrationsController, :type => :routing do
  it "routes to the new user registration action." do
    expect(:get => new_user_registration_path).
      to route_to(:controller => "auth/registrations", :action => "new")
  end
end

RSpec.describe Auth::OmniauthCallbacksController, :type => :routing do
  it "routes to the omniauth failure path" do
    expect(:get => omniauth_failure_path).
      to route_to(:controller => "auth/omniauth_callbacks", :action => "failure")
  end
end
=end