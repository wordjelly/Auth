require 'rails_helper'

RSpec.describe "auth/admin_create_users/new", type: :view do
  before(:each) do
    assign(:auth_admin_create_user, Auth::AdminCreateUser.new())
  end

  it "renders new auth_admin_create_user form" do
    render

    assert_select "form[action=?][method=?]", auth_admin_create_users_path, "post" do
    end
  end
end
