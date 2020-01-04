require 'rails_helper'

RSpec.describe "worms/edit", type: :view do
  before(:each) do
    @worm = assign(:worm, Worm.create!())
  end

  it "renders the edit worm form" do
    render

    assert_select "form[action=?][method=?]", worm_path(@worm), "post" do
    end
  end
end
