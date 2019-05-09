# @Documentation : Refer to README , SECTION : TOKEN_AUTHENTICATION.
module Auth::Concerns::TokenConcern

  extend ActiveSupport::Concern
  
  included do 

    attr_accessor :authentication_done

=begin
    -first looks for a class variable called @tconditions
    this can be conveniently set from a controller that implements this concern, before including the concern.
    -if that is not found, checks if TCONDITIONS , has already been defined, and if yes, does nothing.
    -if none of them have been specified, sets TCONDITIONS to block all actions of the controller, with authentication.
=end
    if defined? @tconditions
      TCONDITIONS = @tconditions
    elsif defined? TCONDITIONS
    
    else
      TCONDITIONS = {:only => [:index,:edit,:show,:create,:update,:new, :destroy, :delete]}
    end
=begin
    Similar strategy is used for last_fallback.
=end
    if defined? @last_fallback
      LAST_FALLBACK = @last_fallback
    elsif defined? LAST_FALLBACK
    else
      LAST_FALLBACK = :devise
    end

    
    #puts "the tconditions become:"
    #puts TCONDITIONS

    #puts "the last fallback becomes:"
    #puts LAST_FALLBACK
    #LAST_FALLBACK = :devise unless defined? LAST_FALLBACK


    if Auth.configuration.enable_token_auth
        
      #puts "TCONDITIONS ARE: #{TCONDITIONS}"
      ## how many models are defined in the preinitializer
      auth_resources_count = Auth.configuration.auth_resources.size

      #puts "auth_resources count:"
      #puts auth_resources_count.to_s
      res = Auth.configuration.auth_resources.keys[0]
      #puts "the TCONDITIONS ARE: #{self::TCONDITIONS}"
      #acts_as_token_authentication_handler_for(res.constantize,Auth.configuration.auth_resources[res].merge({:fallback => self::LAST_FALLBACK}).merge(self::TCONDITIONS || {}))

      ## if we have more than one auth resource model.
      if auth_resources_count > 1
          ## take all of them except the last, and add the fallback as none to them.
          ## also merge the controller level conditions defined above.
          #puts "there is more than one."
          Auth.configuration.auth_resources.keys.slice(0,auth_resources_count - 1).each do |res|

            acts_as_token_authentication_handler_for(res.constantize,Auth.configuration.auth_resources[res].merge({:fallback => :none}).merge(self::TCONDITIONS))

            
           
          end
          ## for the last one, just dont add the fallback as none, other conditions are the same.
          res = Auth.configuration.auth_resources.keys[-1]
         
          acts_as_token_authentication_handler_for(res.constantize,Auth.configuration.auth_resources[res].merge({:fallback => self::LAST_FALLBACK}).merge(self::TCONDITIONS || {}))
          

      else
        ## in case there is only one authentication resource, then the conditions are like the last one in case there are multiple(like above.)
        res = Auth.configuration.auth_resources.keys[0]
        #puts "the last resource is:"
        #puts "the action is: #{action_name}"
        #puts res.to_s
        #puts "conditions are:"
        
        acts_as_token_authentication_handler_for(res.constantize,Auth.configuration.auth_resources[res].merge({:fallback => self::LAST_FALLBACK}).merge(self::TCONDITIONS || {}))
        #puts "crosses token auth handler"
      end


    end


    before_action :set_resource

    ## made this a helper so that it can be used in views as well.
    helper_method :lookup_resource

    helper_method :current_signed_in_resource
  end

  ## iterates all the authentication resources in the config.
  ## tries to see if we have a current_resource for any of them
  ## if yes, sets the resource to the first encoutered such key and breaks the iteration
  ## basically a convenience method to set @resource variable, since when we have more than one model that is being authenticated with Devise, there is no way to know which one to call.
  def set_resource
  
    puts "--------------------came to set resource."

    Auth.configuration.auth_resources.keys.each do |resource|
      break if @resource = self.send("current_#{resource.downcase}") 
    end

    ## devise in registrations_controller#destroy assumes the existence of an 'resource' variable, so we set that here.
    if devise_controller?
      self.resource = @resource
    end

    #puts "resource is: #{@resource.to_s}"
    
  end


  
  def lookup_resource 
    puts "came to lookup resource."
    ## if the current signed in resource si not an admin, just return it, because the concept of proxy arises only if the current_signed in resource is an admin.
    #puts "current signed in resource : #{current_signed_in_resource}"
    return current_signed_in_resource unless current_signed_in_resource.is_admin?
    #puts "crossed resource."
    ## else.
    
    ## first check the session or the params for a proxy resource.
    proxy_resource_id = params[:proxy_resource_id] || session[:proxy_resource_id]
    proxy_resource_class = params[:proxy_resource_class] || session[:proxy_resource_class]
    
    
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
    not_found("not authorized") unless current_signed_in_resource
    not_found("You don't have sufficient privileges to complete that action") if !current_signed_in_resource.is_admin?
  end

end