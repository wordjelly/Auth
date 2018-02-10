require 'rails_helper'

RSpec.describe "auth/admin_create_users/index", type: :view do
  before(:each) do
    assign(:auth_admin_create_users, [
      Auth::AdminCreateUser.create!(),
      Auth::AdminCreateUser.create!()
    ])
  end

  it "renders a list of auth/admin_create_users" do
    render
  end
end
