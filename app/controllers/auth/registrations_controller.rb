class Auth::RegistrationsController < Devise::RegistrationsController
  
  after_action :check_resource_errors

  private
	def check_resource_errors
		puts resource.attributes.to_s
		true
	end
  

end
