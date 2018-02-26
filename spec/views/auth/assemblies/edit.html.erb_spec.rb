require 'rails_helper'

RSpec.describe "auth/assemblies/edit", type: :view do
  before(:each) do
    @auth_assembly = assign(:auth_assembly, Auth::Assembly.create!())
  end

  it "renders the edit auth_assembly form" do
    render

    assert_select "form[action=?][method=?]", auth_assembly_path(@auth_assembly), "post" do
    end
  end
end
