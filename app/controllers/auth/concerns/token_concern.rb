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

    
    TCONDITIONS = {} unless defined? TCONDITIONS


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
         
          acts_as_token_authentication_handler_for(res.constantize,Auth.configuration.auth_resources[res].merge(self::TCONDITIONS || {}))
          

      else
        ## in case there is only one authentication resource, then the conditions are like the last one in case there are multiple(like above.)
        res = Auth.configuration.auth_resources.keys[0]
       
        acts_as_token_authentication_handler_for(res.constantize,Auth.configuration.auth_resources[res].merge(self::TCONDITIONS || {}))

      end
    
    end

    before_filter :set_resource

    ## made this a helper so that it can be used in views as well.
    helper_method :lookup_resource

    helper_method :current_signed_in_resource
  end

  ## iterates all the authentication resources in the config.
  ## tries to see if we have a current_resource for any of them
  ## if yes, sets the resource to the first encoutered such key and breaks the iteration
  ## basically a convenience method to set @resource variable, since when we have more than one model that is being authenticated with Devise, there is no way to know which one to call.
  def set_resource
    

    Auth.configuration.auth_resources.keys.each do |resource|
      break if @resource = self.send("current_#{resource.downcase}") 
    end

    #puts "do we have a resource"
    #puts @resource.to_s

    ## devise in registrations_controller#destroy assumes the existence of an 'resource' variable, so we set that here.
    if devise_controller?
      self.resource = @resource
    end

   
    
  end


  
  def lookup_resource 
    puts "came to lookup resource."
    ## if the current signed in resource si not an admin, just return it, because the concept of proxy arises only if the current_signed in resource is an admin.
    puts "current signed in resource : #{current_signed_in_resource}"
    return current_signed_in_resource unless current_signed_in_resource.is_admin?
    puts "crossed resource."
    ## else.
    
    ## first check the session or the params for a proxy resource.
    proxy_resource_id = params[:proxy_resource_id] || session[:proxy_resource_id]
    proxy_resource_class = params[:proxy_resource_class] || session[:proxy_resource_class]
    
    ## if these are not provided or set, and if the resource is an admin, then the admin becomes the proxy_resource
    proxy_resource_id = current_signed_in_resource.id.to_s if (current_signed_in_resource.is_admin? && proxy_resource_id.nil?)

    proxy_resource_class = current_signed_in_resource.class.to_s if (current_signed_in_resource.is_admin? && proxy_resource_class.nil?)

    ## now return nil if the proxy resource is still nil.
    return nil unless (proxy_resource_class && proxy_resource_id)
    return nil unless (Auth.configuration.auth_resources.include? proxy_resource_class.capitalize)

    proxy_resource_class = proxy_resource_class.capitalize.constantize
    begin
      proxy_resource = proxy_resource_class.find(proxy_resource_id)
      proxy_resource
    rescue Mongoid::Errors::DocumentNotFound => error
      nil
    end
    
  end  

  ## the current signed in resource.
  def current_signed_in_resource
    @resource
  end


  ## convenience method to add the current signed in resource to the model instance.
  ## the object instance passed in MUST implement the owner concern
  ## @param[Object] : instance of any object that implements the OwnerConcern.
  ## @return : the object passed in.
  def add_signed_in_resource(obj,options={})
        if obj.respond_to? :signed_in_resource
          obj.signed_in_resource = current_signed_in_resource
        end
        return obj
  end

  ## only adds the owner resource if its not already present, implying that once the owner resource is set, it should never change.
  def add_owner_resource(obj,options={})
      if (obj.respond_to? :resource_id) && (obj.respond_to? :resource_class)
        if options[:owner_is_current_resource]
          obj.resource_id = current_signed_in_resource.id.to_s if obj.resource_id.nil?
          obj.resource_class = current_signed_in_resource.class.name.to_s if obj.resource_class.nil?
        else
          obj.resource_id = lookup_resource.id.to_s if obj.resource_id.nil?
          obj.resource_class = lookup_resource.class.name.to_s if obj.resource_class.nil?
        end
      end
      return obj
  end

  ## @param[Object] obj: the object whose owner is to be defined.
  ## @param[Hash] options: possible options include:
  ## :owner_is_current_resource => if this option exists, the resource_id and resource_class is set to the current resource
  def add_owner_and_signed_in_resource(obj,options={})
    obj = add_owner_resource(obj,options)
    obj = add_signed_in_resource(obj,options)
    obj
  end

  ## this is used as a before_filter.
  def is_admin_user
    not_found("You don't have sufficient privileges to complete that action") if !current_signed_in_resource.is_admin?
  end

end