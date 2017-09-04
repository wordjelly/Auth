class Auth::RegistrationsController < Devise::RegistrationsController
	include Auth::Concerns::TokenConcern
	before_action :check_recaptcha, only: [:create, :update]
	def self.token_authentication_conditions
		{:only => [:edit,:update,:destroy]}
	end
end
