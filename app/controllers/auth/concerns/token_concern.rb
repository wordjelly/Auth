module Auth::Concerns::TokenConcern

  extend ActiveSupport::Concern
  
  included do 
  	
  	##for each of the resources that are defined with token_auth
  	##it should act as token authenticatable.
  	if Auth.configuration.enable_token_auth
		Auth.configuration.auth_resources.each do |res,opts|
			acts_as_token_authentication_handler_for(res.constantize,opts)
		end  	
	end

  end

end