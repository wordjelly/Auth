module Auth
	module OmniAuth
		module Path
			##this consists of the mount path / omniauth / resource_pluralized / provider
			def self.omniauth_request_path(resource,provider)
				"#{omniauth_prefix_path}/#{resource_pluralized(resource)}/#{provider}"
			end

			def self.omniauth_prefix_path
				"#{Auth.configuration.mount_path}/omniauth"
			end

			def self.common_callback_path(provider)
				"#{omniauth_prefix_path}/#{provider}/callback"
			end

			def self.resource_pluralized(resource)
				resource.to_s.pluralize.underscore.gsub('/', '_')
			end

			def self.resource_path(resource)
				"#{Auth.configuration.mount_path}/#{resource_pluralized resource}"
			end
		end
	end

end