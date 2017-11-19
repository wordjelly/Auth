module Auth::Concerns::TokenConcern

  extend ActiveSupport::Concern
  
  included do 
  	
  	## adds simple_token_authentication to whichever controller implements this concern.
    ## the models have alredy been made token_authenticatable in the lib/auth/omniauth.rb file
    ## logic implemented here is that it iterates the auth_resources one at a time, and as long as the previous one is not already signed in , will add the 'acts_as_token_authentication_handler_for' the current resource_type.
    ## merges in the entire hash for the current resource_type, from the configuration preinitializer file.
    ## it then merges in any controller level configuration options
    ## for this purpose, the controller should add a class method called 'token_authentication_conditions', which should return a hash of options. Refer to models/auth/shopping/cart_concern.rb and model/auth/shopping/cart_item_concern.rb to see how this has been implemented. Only options supported by simple_token_authentication can be set in the hash. 

    ### Example how to add it in the controller

=begin
    ### in this case, the token authentication will be done on all actions defined below.
    ### so it won't be done on "show"
    module ClassMethods
      def token_authentication_conditions
        {:only => [:create,:update,:destroy,:index]}
      end
    end
=end

    ### Example ends


    if Auth.configuration.enable_token_auth
      
      token_auth_controller_conditions = self.respond_to?(:token_authentication_conditions) ? self.token_authentication_conditions : {}

  		Auth.configuration.auth_resources.keys.each_with_index {|res,i|
        if i > 0
  			 prev_resource = Auth.configuration.auth_resources.keys[i - 1]
         acts_as_token_authentication_handler_for(res.constantize,Auth.configuration.auth_resources[res].merge(:unless => lambda { |controller| send("#{prev_resource.downcase}_signed_in?") }).merge(token_auth_controller_conditions)) 
        else
          acts_as_token_authentication_handler_for(res.constantize,Auth.configuration.auth_resources[res].merge(token_auth_controller_conditions))
        end

  		}
      
    end

    before_filter :set_resource

    ## made this a helper so that it can be used in views as well.
    helper_method :lookup_resource

  end

  ## iterates all the authentication resources in the config.
  ## tries to see if we have a current_resource for any of them
  ## if yes, sets the resource to the first encoutered such key and breaks the iteration
  ## basically a convenience method to set @resource variable, since when we have more than one model that is being authenticated with Devise, there is no way to know which one to call.
  def set_resource

    Auth.configuration.auth_resources.keys.each do |resource|
      break if @resource = self.send("current_#{resource.downcase}") 
    end

    ## devise in registrations_controller#destroy assumes the existence of an 'resource' variable, so we set that here.
    if devise_controller?
      self.resource = @resource
    end

    # this line is not necessary, since simple_token_authentication already throws non-authorized error if the resource is not signed in.
    #self.send("authenticate_#{Auth.configuration.auth_resources.keys[0].downcase}!") if @resource.nil?
  end


  ##this method is to be overridden in the daughter application to allow for a resource to be proxied, for eg, when an administrator wants to make changes on behalf of a resource 
  ##this method simply returns the resource calculated in the #authenticate_and_set_resource method, for the moment.It should be overridden depending on app requirements.
  ##for example one strategy would be to store the resource to be proxied into the session, and reference that here, if the logged in resource is an admin.
  ##best strategy would be to pick up a :resource_id from the params, and use that everywhere.
  ##provided that the signed in resource is an admin.
  def lookup_resource
    @resource
  end

  
 

end