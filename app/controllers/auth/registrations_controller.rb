class Auth::RegistrationsController < Devise::RegistrationsController

  def update_resource(resource, params)
  	puts "update params are: #{params.to_s}"
    resource.update_with_password(params)
  end

  
end
