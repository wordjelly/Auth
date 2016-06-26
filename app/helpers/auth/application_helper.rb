module Auth
  module ApplicationHelper
  	def omniauth_authorize_path(resource_or_scope, provider, *args)
  		"#{request.base_url}#{Auth::OmniAuth::Path.omniauth_request_path(resource_or_scope,provider)}"
  	end

  	def omniauth_failed_path_for
  		Auth::Engine.routes.url_helpers.omniauth_failure_path
  	end
  	
  end
end
