class Auth::RegistrationsController < Devise::RegistrationsController
  include Auth::Concerns::ControllerAdditionalLoginParamConcern
  after_action :check_resource_errors
  

  private
	def check_resource_errors
		puts resource.attributes.to_s
		puts resource.errors.full_messages.to_s
		true
	end
  	
  	

end
