class User::ParameterSanitizer < Devise::ParameterSanitizer
  def initialize(resource_class, resource_name, params)
    super(resource_class, resource_name, params)
   	## the name has no real role here.
   	## the parameters specified here, get added to the default permitted parameters.
  	permit(:sign_up, keys: Auth.configuration.auth_resources[resource_class.to_s][:login_params])
  	permit(:account_update, keys: Auth.configuration.auth_resources[resource_class.to_s][:login_params])
  end
end

