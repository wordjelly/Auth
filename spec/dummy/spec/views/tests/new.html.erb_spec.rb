require 'rails_helper'

RSpec.describe "tests/new", type: :view do
  before(:each) do
    assign(:test, Test.new(
      :price => 1.5,
      :name => "MyText"
    ))
  end

  it "renders new test form" do
    render

    assert_select "form[action=?][method=?]", tests_path, "post" do

      assert_select "input#test_price[name=?]", "test[price]"

      assert_select "textarea#test_name[name=?]", "test[name]"
    end
  end
end
