require "rails_helper"

RSpec.describe "admins routes", :type => :routing do 
  
  it "routes sessions requests to the controllers defined in the configuration file in the app itself" do
    expect(get(new_admin_session_path)).
      to route_to(:controller => "admins/sessions", :action => "new")
  end

  it "routes registration requests to the default controllers" do 
  	expect(get(new_admin_registration_path)).
  	to route_to(:controller => "auth/registrations", :action => "new")
  end

end