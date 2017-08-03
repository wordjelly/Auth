require 'rails_helper'

RSpec.describe "tests/edit", type: :view do
  before(:each) do
    @test = assign(:test, Test.create!(
      :price => 1.5,
      :name => "MyText"
    ))
  end

  it "renders the edit test form" do
    render

    assert_select "form[action=?][method=?]", test_path(@test), "post" do

      assert_select "input#test_price[name=?]", "test[price]"

      assert_select "textarea#test_name[name=?]", "test[name]"
    end
  end
end
