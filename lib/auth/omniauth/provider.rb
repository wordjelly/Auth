module Auth
	module OmniAuth
		module Provider
			##calls the oauth provider to get information.
			##sets the token_expired on the resource in case it has expired
			##if the authentication fails, then returns authentication failure
			##otherwise returns the user information.
			def self.call_oauth_provider
			end	
		end
	end
end