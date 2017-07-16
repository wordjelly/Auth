class User::ParameterSanitizer < Devise::ParameterSanitizer

  def initialize(resource_class, resource_name, params)
    super(resource_class, resource_name, params)
    puts resource_class
    permit(:sign_up, keys: [Auth.configuration.auth_resources[resource_class.to_s][:additional_login_param][:name].to_sym])
  end

end