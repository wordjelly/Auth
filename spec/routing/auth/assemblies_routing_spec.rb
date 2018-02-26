require "rails_helper"

RSpec.describe Auth::AssembliesController, type: :routing do
  describe "routing" do

    it "routes to #index" do
      expect(:get => "/auth/assemblies").to route_to("auth/assemblies#index")
    end

    it "routes to #new" do
      expect(:get => "/auth/assemblies/new").to route_to("auth/assemblies#new")
    end

    it "routes to #show" do
      expect(:get => "/auth/assemblies/1").to route_to("auth/assemblies#show", :id => "1")
    end

    it "routes to #edit" do
      expect(:get => "/auth/assemblies/1/edit").to route_to("auth/assemblies#edit", :id => "1")
    end

    it "routes to #create" do
      expect(:post => "/auth/assemblies").to route_to("auth/assemblies#create")
    end

    it "routes to #update via PUT" do
      expect(:put => "/auth/assemblies/1").to route_to("auth/assemblies#update", :id => "1")
    end

    it "routes to #update via PATCH" do
      expect(:patch => "/auth/assemblies/1").to route_to("auth/assemblies#update", :id => "1")
    end

    it "routes to #destroy" do
      expect(:delete => "/auth/assemblies/1").to route_to("auth/assemblies#destroy", :id => "1")
    end

  end
end
