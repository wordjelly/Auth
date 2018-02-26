require 'rails_helper'

RSpec.describe "auth/assemblies/show", type: :view do
  before(:each) do
    @auth_assembly = assign(:auth_assembly, Auth::Assembly.create!())
  end

  it "renders attributes in <p>" do
    render
  end
end
