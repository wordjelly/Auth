module Auth::Concerns::TokenConcern

  extend ActiveSupport::Concern
  
  included do 
  	if Auth.configuration.enable_token_auth
  		
  		acts_as_token_authentication_handler_for User,Auth.configuration.auth_resources["User"]["token_auth_options"]
  		
  	end

  end

end