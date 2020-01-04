class Auth::UnlocksController < Devise::UnlocksController
  	include Auth::Concerns::DeviseConcern  

end
