module Auth::Concerns::TokenConcern

  extend ActiveSupport::Concern
  
  included do 
  	if Auth.configuration.enable_token_auth
  		
  		acts_as_token_authentication_handler_for self.class,Auth.configuration.auth_resources[self.name]["token_auth_options"]
  		
  	end

  end

end