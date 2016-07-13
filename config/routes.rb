Auth::Engine.routes.draw do

  
  	resources :clients

	##OAUTH FAILURE ROUTE.
	oauth_failure_path = Auth::OmniAuth::Path.omniauth_failure_path
	match "#{oauth_failure_path}", controller: "omniauth_callbacks", action: "failure", via:[:get,:post], as: "omniauth_failure"

	
end

