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

    before_filter :authenticate_and_set_resource

  end

  ##iterates all the authentication resources in the config.
  ##tries to see if we have a current_resource for any of them
  ##if yes, sets the resource to the first encoutered such key and breaks the iteration
  ##at the end if we still don't have a resource, then calls the authenticate_resource! method on the first resource in the config. 
  def authenticate_and_set_resource
    Auth.configuration.auth_resources.keys.each do |resource|
      break if @resource = self.send("current_#{resource.downcase}") 
    end
    self.send("authenticate_#{Auth.configuration.auth_resources.keys[0].downcase}!") if @resource.nil?
  end

end