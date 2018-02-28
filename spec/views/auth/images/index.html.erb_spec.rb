require 'rails_helper'

RSpec.describe "auth/images/index", type: :view do
  before(:each) do
    assign(:auth_images, [
      Auth::Image.create!(),
      Auth::Image.create!()
    ])
  end

  it "renders a list of auth/images" do
    render
  end
end
