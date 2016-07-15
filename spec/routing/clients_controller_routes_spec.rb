require "rails_helper"
=begin
clients 	GET    /clients(.:format)          auth/clients#index
            POST   /clients(.:format)          auth/clients#create
 new_client GET    /clients/new(.:format)      auth/clients#new
edit_client GET    /clients/:id/edit(.:format) auth/clients#edit
     client GET    /clients/:id(.:format)      auth/clients#show
            PATCH  /clients/:id(.:format)      auth/clients#update
            PUT    /clients/:id(.:format)      auth/clients#update
            DELETE /clients/:id(.:format)      auth/clients#destroy

=end
RSpec.describe Auth::ClientsController, :type => :routing do 
  routes{Auth::Engine.routes}
  it "routes to the list of all clients" do
    expect(:get => "clients").
      to route_to(:controller => "auth/clients", :action => "index")
  end
end

RSpec.describe Auth::ClientsController, :type => :routing do 
  routes{Auth::Engine.routes}
  it "creates a new client" do
    expect(:post => "clients").
      to route_to(:controller => "auth/clients", :action => "create")
  end
end

RSpec.describe Auth::ClientsController, :type => :routing do 
  routes{Auth::Engine.routes}
  it "gets a new client" do
    expect(:get => "clients/new").
      to route_to(:controller => "auth/clients", :action => "new")
  end
end

RSpec.describe Auth::ClientsController, :type => :routing do 
  routes{Auth::Engine.routes}
  it "renders edit for the given client" do
    expect(:get => "clients/abc/edit").
      to route_to(:controller => "auth/clients", :action => "edit", :id => 'abc')
  end
end

RSpec.describe Auth::ClientsController, :type => :routing do 
  routes{Auth::Engine.routes}
  it "shows the given client." do
    expect(:get => "clients/abc").
      to route_to(:controller => "auth/clients", :action => "show", :id => 'abc')
  end
end

RSpec.describe Auth::ClientsController, :type => :routing do 
  routes{Auth::Engine.routes}
  it "updates the given client." do
    expect(:put => "clients/abc").
      to route_to(:controller => "auth/clients", :action => "update", :id => 'abc')
  end
end

RSpec.describe Auth::ClientsController, :type => :routing do 
  routes{Auth::Engine.routes}
  it "updates the given client." do
    expect(:patch => "clients/abc").
      to route_to(:controller => "auth/clients", :action => "update", :id => 'abc')
  end
end

RSpec.describe Auth::ClientsController, :type => :routing do 
  routes{Auth::Engine.routes}
  it "deletes the given client." do
    expect(:delete => "clients/abc").
      to route_to(:controller => "auth/clients", :action => "destroy", :id => 'abc')
  end
end