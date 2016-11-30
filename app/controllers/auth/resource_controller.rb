class Auth::ResourceController < ApplicationController
		
	include Auth::Concerns::TokenConcern
	#include Auth::OmniAuth::Provider

	def index
		##can permit only certain things.
		##name, picture.
	end

		

end
