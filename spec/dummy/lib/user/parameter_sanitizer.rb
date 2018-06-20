class User::ParameterSanitizer < Devise::ParameterSanitizer
  def initialize(resource_class, resource_name, params)
    super(resource_class, resource_name, params)
  	permit(:sign_up, keys: Auth.configuration.auth_resources[resource_class.to_s][:login_params] + [:name])
  	permit(:account_update, keys: Auth.configuration.auth_resources[resource_class.to_s][:login_params] + [:name,:android_token,:ios_token])
  end
end

