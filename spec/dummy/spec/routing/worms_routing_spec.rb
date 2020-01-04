require "rails_helper"

RSpec.describe WormsController, type: :routing do
  describe "routing" do

    it "routes to #index" do
      expect(:get => "/worms").to route_to("worms#index")
    end

    it "routes to #new" do
      expect(:get => "/worms/new").to route_to("worms#new")
    end

    it "routes to #show" do
      expect(:get => "/worms/1").to route_to("worms#show", :id => "1")
    end

    it "routes to #edit" do
      expect(:get => "/worms/1/edit").to route_to("worms#edit", :id => "1")
    end

    it "routes to #create" do
      expect(:post => "/worms").to route_to("worms#create")
    end

    it "routes to #update via PUT" do
      expect(:put => "/worms/1").to route_to("worms#update", :id => "1")
    end

    it "routes to #update via PATCH" do
      expect(:patch => "/worms/1").to route_to("worms#update", :id => "1")
    end

    it "routes to #destroy" do
      expect(:delete => "/worms/1").to route_to("worms#destroy", :id => "1")
    end

  end
end
