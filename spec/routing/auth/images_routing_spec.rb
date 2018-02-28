require "rails_helper"

RSpec.describe Auth::ImagesController, type: :routing do
  describe "routing" do

    it "routes to #index" do
      expect(:get => "/auth/images").to route_to("auth/images#index")
    end

    it "routes to #new" do
      expect(:get => "/auth/images/new").to route_to("auth/images#new")
    end

    it "routes to #show" do
      expect(:get => "/auth/images/1").to route_to("auth/images#show", :id => "1")
    end

    it "routes to #edit" do
      expect(:get => "/auth/images/1/edit").to route_to("auth/images#edit", :id => "1")
    end

    it "routes to #create" do
      expect(:post => "/auth/images").to route_to("auth/images#create")
    end

    it "routes to #update via PUT" do
      expect(:put => "/auth/images/1").to route_to("auth/images#update", :id => "1")
    end

    it "routes to #update via PATCH" do
      expect(:patch => "/auth/images/1").to route_to("auth/images#update", :id => "1")
    end

    it "routes to #destroy" do
      expect(:delete => "/auth/images/1").to route_to("auth/images#destroy", :id => "1")
    end

  end
end
