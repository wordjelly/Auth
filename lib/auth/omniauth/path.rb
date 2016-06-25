module Auth
	module OmniAuth
		module Path

			##the the path for the request_phase of the omniauth call.
			def self.omniauth_request_path(resource,provider)
				"#{omniauth_prefix_path}/#{resource_pluralized(resource)}/#{provider}"
			end

			##the omniauth prefix = mount_path/omniauth
			def self.omniauth_prefix_path
				"#{Auth.configuration.mount_path}/omniauth"
			end

			##the path for the callback is the same for all models.
			def self.common_callback_path(provider)
				"#{omniauth_prefix_path}/#{provider}/callback"
			end

			def self.resource_pluralized(resource)
				resource.to_s.pluralize.underscore.gsub('/', '_')
			end

			##the path prefix for all the devise modules.
			def self.resource_path(resource)	
				"#{Auth.configuration.mount_path}/#{resource_pluralized resource}"
			end

			##the path for the omniauth_failure, it is the same for all models 
			def self.omniauth_failure_path
				"#{omniauth_prefix_path}/failed"
			end
		end
	end

end