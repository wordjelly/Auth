module Auth
  module ApplicationHelper
  	def omniauth_authorize_path(resource_or_scope, provider, *args)
  		"#{request.base_url}#{Auth::OmniAuth::Path.omniauth_request_path(resource_or_scope,provider)}"
  	end
  end
end
