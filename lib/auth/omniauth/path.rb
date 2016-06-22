module Auth
	module OmniAuth
		module Path
			##this consists of the mount path / omniauth / resource_pluralized / provider
			def self.omniauth_request_path(resource_or_scope,provider)
				resource_as_pluralized_string = resource_or_scope.to_s.pluralize.underscore.gsub('/', '_')
				"#{MOUNT_PATH}/omniauth/#{resource_as_pluralized_string}/#{provider}"
			end


			def self.common_callback_path(provider)
				"#{MOUNT_PATH}/omniauth/#{provider}/callback"
			end
		end
	end

end