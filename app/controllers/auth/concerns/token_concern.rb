module Auth::Concerns::TokenConcern

  extend ActiveSupport::Concern


 
  included do 
  	if Auth.configuration.enable_token_auth
  		Auth.configuration.auth_resources.each do |model,opts|
  			if !opts["token_auth_lambda"].nil? && !opts["token_auth_condition"].nil?
  				acts_as_token_authentication_handler_for Object.const_get model,{ fallback: opts["token_auth_fallback"].to_sym, opts["token_auth_condition"].to_sym opts["token_auth_lambda"]}
  			else
  				acts_as_token_authentication_handler_for Object.const_get model,{fallback: opts["token_auth_fallback"].to_sym}
  			end
  		end
  	end

  end

end