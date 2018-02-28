require 'rails_helper'

RSpec.describe "auth/images/edit", type: :view do
  before(:each) do
    @auth_image = assign(:auth_image, Auth::Image.create!())
  end

  it "renders the edit auth_image form" do
    render

    assert_select "form[action=?][method=?]", auth_image_path(@auth_image), "post" do
    end
  end
end
