require 'rails_helper'

RSpec.describe "tests/show", type: :view do
  before(:each) do
    @test = assign(:test, Test.create!(
      :price => 2.5,
      :name => "MyText"
    ))
  end

  it "renders attributes in <p>" do
    render
    expect(rendered).to match(/2.5/)
    expect(rendered).to match(/MyText/)
  end
end
