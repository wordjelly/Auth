require 'rails_helper'

RSpec.describe "auth/assemblies/index", type: :view do
  before(:each) do
    assign(:auth_assemblies, [
      Auth::Assembly.create!(),
      Auth::Assembly.create!()
    ])
  end

  it "renders a list of auth/assemblies" do
    render
  end
end
