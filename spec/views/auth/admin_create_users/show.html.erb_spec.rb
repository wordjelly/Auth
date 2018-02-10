require 'rails_helper'

RSpec.describe "auth/admin_create_users/show", type: :view do
  before(:each) do
    @auth_admin_create_user = assign(:auth_admin_create_user, Auth::AdminCreateUser.create!())
  end

  it "renders attributes in <p>" do
    render
  end
end
