class User::ParameterSanitizer < Devise::ParameterSanitizer
  ##so if you dont want to have
  def initialize(resource_class, resource_name, params)
    super(resource_class, resource_name, params)
  	permit(:sign_up, keys: Auth.configuration.auth_resources[resource_class.to_s][:login_params])
  	permit(:account_update, keys: Auth.configuration.auth_resources[resource_class.to_s][:login_params])
  end

end

