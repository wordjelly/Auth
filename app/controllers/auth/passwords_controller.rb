class Auth::PasswordsController < Devise::PasswordsController

	include Auth::Concerns::DeviseConcern  

end
