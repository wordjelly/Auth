require 'rails_helper'

RSpec.describe "worms/show", type: :view do
  before(:each) do
    @worm = assign(:worm, Worm.create!())
  end

  it "renders attributes in <p>" do
    render
  end
end
