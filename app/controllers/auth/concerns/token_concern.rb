module Auth::Concerns::TokenConcern

  extend ActiveSupport::Concern
  
  included do 
  	
    attr_accessor :authentication_done

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
    
=end

    ### Example ends

    ## POINT B:
    ## so as per documentation of simple-token-authentication, if multiple models are to be handled for token auth then all but the last must have a fallback of :none in case of authentication failure.
    ## this is so that it doesnt fail on the first model.
    ## and at least tries all the remaining models.
    ## So if there is only one model : then its fallback is default.
    ## if there is more than one model : all but the last will have a fallback of :none.
    ## 

    if Auth.configuration.enable_token_auth
        
      ## conditions can be defined at the controller level .
      ## include a constant called TCONDITIONS, before the line 
      ## include Auth::Concerns::TokenConcern
      ## refer to Auth::RegistrationsController or implementation.
      
      


      ## how many models are defined in the preinitializer
      auth_resources_count = Auth.configuration.auth_resources.size

      

      ## if we have more than one auth resource model.
      if auth_resources_count > 1
          ## take all of them except the last, and add the fallback as none to them.
          ## also merge the controller level conditions defined above.
         
          Auth.configuration.auth_resources.keys.slice(0,auth_resources_count - 1).each do |res|

            acts_as_token_authentication_handler_for(res.constantize,Auth.configuration.auth_resources[res].merge({:fallback => :none}).merge(self::TCONDITIONS))

            
           
          end
          ## for the last one, just dont add the fallback as none, other conditions are the same.
          res = Auth.configuration.auth_resources.keys[-1]
         
          acts_as_token_authentication_handler_for(res.constantize,Auth.configuration.auth_resources[res].merge(self::TCONDITIONS))
          

      else
        ## in case there is only one authentication resource, then the conditions are like the last one in case there are multiple(like above.)
        res = Auth.configuration.auth_resources.keys[0]
       
        acts_as_token_authentication_handler_for(res.constantize,Auth.configuration.auth_resources[res].merge(self::TCONDITIONS))

      end
    
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
  ## override as needed.
  def lookup_resource
    current_signed_in_resource
  end  

  ## the current signed in resource.
  def current_signed_in_resource
    @resource
  end

  ## convenience method to add the current signed in resource to the model instance.
  ## the object instance passed in MUST implement the owner concern
  ## @param[Object] : instance of any object that implements the OwnerConcern.
  ## @return : the object passed in.
  def add_signed_in_resource(obj)
        obj.signed_in_resource = current_signed_in_resource
        obj
  end

  def dog
    "eys"
  end

end