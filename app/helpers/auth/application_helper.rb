module Auth
  module ApplicationHelper
  	def omniauth_authorize_path(resource_or_scope, provider, *args)
  		"#{request.base_url}#{MOUNT_PATH}/omniauth/#{provider}"
  	end
  end
end
