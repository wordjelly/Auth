require 'rails_helper'

RSpec.describe "worms/new", type: :view do
  before(:each) do
    assign(:worm, Worm.new())
  end

  it "renders new worm form" do
    render

    assert_select "form[action=?][method=?]", worms_path, "post" do
    end
  end
end
