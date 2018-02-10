require "rails_helper"

RSpec.describe Auth::AdminCreateUsersController, type: :routing do
  describe "routing" do

    it "routes to #index" do
      expect(:get => "/auth/admin_create_users").to route_to("auth/admin_create_users#index")
    end

    it "routes to #new" do
      expect(:get => "/auth/admin_create_users/new").to route_to("auth/admin_create_users#new")
    end

    it "routes to #show" do
      expect(:get => "/auth/admin_create_users/1").to route_to("auth/admin_create_users#show", :id => "1")
    end

    it "routes to #edit" do
      expect(:get => "/auth/admin_create_users/1/edit").to route_to("auth/admin_create_users#edit", :id => "1")
    end

    it "routes to #create" do
      expect(:post => "/auth/admin_create_users").to route_to("auth/admin_create_users#create")
    end

    it "routes to #update via PUT" do
      expect(:put => "/auth/admin_create_users/1").to route_to("auth/admin_create_users#update", :id => "1")
    end

    it "routes to #update via PATCH" do
      expect(:patch => "/auth/admin_create_users/1").to route_to("auth/admin_create_users#update", :id => "1")
    end

    it "routes to #destroy" do
      expect(:delete => "/auth/admin_create_users/1").to route_to("auth/admin_create_users#destroy", :id => "1")
    end

  end
end
