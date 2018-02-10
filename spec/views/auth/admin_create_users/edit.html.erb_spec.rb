require 'rails_helper'

RSpec.describe "auth/admin_create_users/edit", type: :view do
  before(:each) do
    @auth_admin_create_user = assign(:auth_admin_create_user, Auth::AdminCreateUser.create!())
  end

  it "renders the edit auth_admin_create_user form" do
    render

    assert_select "form[action=?][method=?]", auth_admin_create_user_path(@auth_admin_create_user), "post" do
    end
  end
end
