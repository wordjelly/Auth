require 'rails_helper'

RSpec.describe "tests/index", type: :view do
  before(:each) do
    assign(:tests, [
      Test.create!(
        :price => 2.5,
        :name => "MyText"
      ),
      Test.create!(
        :price => 2.5,
        :name => "MyText"
      )
    ])
  end

  it "renders a list of tests" do
    render
    assert_select "tr>td", :text => 2.5.to_s, :count => 2
    assert_select "tr>td", :text => "MyText".to_s, :count => 2
  end
end
