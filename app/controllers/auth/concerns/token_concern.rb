module Auth::Concerns::TokenConcern

  extend ActiveSupport::Concern
  
  included do 
  	
  	##for each of the resources that are defined with token_auth
  	##it should act as token authenticatable.
    if Auth.configuration.enable_token_auth
  		Auth.configuration.auth_resources.keys.each_with_index {|res,i|
        if i > 0
  			 prev_resource = Auth.configuration.auth_resources.keys[i - 1]
         acts_as_token_authentication_handler_for(res.constantize,Auth.configuration.auth_resources[res].merge(:unless => lambda { |controller| send("#{prev_resource.downcase}_signed_in?") })) 
        else
          acts_as_token_authentication_handler_for(res.constantize,Auth.configuration.auth_resources[res])
        end

  		}
      
    end

  end

end