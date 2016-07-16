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

			##the absolute path that is returned by the omniauth url helper
			##devise takes care of prepending the resource and the mount prefix.
			def self.omniauth_failure_absolute_path
				"omniauth/failed"
			end

			##this is the path that is used in the routes.rb file, to build
			##the actual route.
			##keeps :res as a wildcard for the required resource.
			def self.omniauth_failure_route_path(resource_or_scope)
				resource_or_scope = resource_or_scope.nil? ? ":res" : resource_pluralized(resource_or_scope.class.name)
				"#{Auth.configuration.mount_path}/#{resource_or_scope}/#{omniauth_failure_absolute_path}"
			end

			##when authentication fails, this path is called.
			def self.authnetication_failed_path_for(resource_or_scope)
				
			end

		end
	end

end