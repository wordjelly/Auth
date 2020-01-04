require 'rails_helper'

RSpec.describe "worms/index", type: :view do
  before(:each) do
    assign(:worms, [
      Worm.create!(),
      Worm.create!()
    ])
  end

  it "renders a list of worms" do
    render
  end
end
