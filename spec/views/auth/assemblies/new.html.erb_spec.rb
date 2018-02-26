require 'rails_helper'

RSpec.describe "auth/assemblies/new", type: :view do
  before(:each) do
    assign(:auth_assembly, Auth::Assembly.new())
  end

  it "renders new auth_assembly form" do
    render

    assert_select "form[action=?][method=?]", auth_assemblies_path, "post" do
    end
  end
end
