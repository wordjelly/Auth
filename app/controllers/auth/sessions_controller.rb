class Auth::SessionsController < Devise::SessionsController
 	
  include Auth::Concerns::DeviseConcern  


  def create
    self.resource = warden.authenticate!(auth_options)
    ## added these two lines
    resource.m_client = self.m_client
 	resource.set_client_authentication
 	## end.
    set_flash_message!(:notice, :signed_in)
    sign_in(resource_name, resource)
    yield resource if block_given?
    respond_with resource, location: after_sign_in_path_for(resource)
  end

end
