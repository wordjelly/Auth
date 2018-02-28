require 'rails_helper'

RSpec.describe "auth/images/new", type: :view do
  before(:each) do
    assign(:auth_image, Auth::Image.new())
  end

  it "renders new auth_image form" do
    render

    assert_select "form[action=?][method=?]", auth_images_path, "post" do
    end
  end
end
