class Auth::RegistrationsController < Devise::RegistrationsController
	before_action :check_recaptcha, only: [:create, :update]
end
