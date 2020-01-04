module Auth
	module OmniAuth
		module Path

			##############################################
			##
			## FOR BUILDING THE PATHS FOR ALL CLASSES.
			##
			##############################################
			## given something like Auth::Shopping::CartItem , will return auth/shopping/cart_item
			## @param[String] cls_name_as_string : the name of the class , as a string.
			## @retunrn[String] the pathified version of the class name.
			def self.pathify(cls_name_as_string)
				cls_name_as_string.split("::").map{|c| c = c.underscore}.join("/")
			end

			def self.new_path(cls)
				"new_" + cls.constantize.new.class.name.underscore.gsub(/\//,"_") + "_path"
			end

			def self.show_or_update_or_delete_path(cls)
				
				parts = cls.constantize.new.class.name.split("::")
				parts.map{|c| c.underscore.downcase}.join("_") + "_path"
			end

				
			def self.create_or_index_path(cls)
				parts = cls.constantize.new.class.name.split("::")
				parts[-1] = parts[-1].pluralize
				parts.map{|c| c.underscore.downcase}.join("_") + "_path"
			end

			def self.edit_path(cls)				
				"edit_" + show_or_update_or_delete_path(cls)
			end

			##############################################
			##
			##
			##
			##############################################


			## given something like : shopping/product
			## will return something like: Shopping::Product
			def self.path_to_model(path)
				path.split("/").map{|c| c = c.capitalize}.join("::").constantize
			end

			## given something like :Shopping::Product
			## will return something like shopping/products
			def self.model_to_path(cls)
				parts = cls.to_s.split("::").map{|c| c = c.to_s.downcase}
				parts[-1] = parts[-1].pluralize
				parts.join("/")
			end

			##the the path for the request_phase of the omniauth call.
			def self.omniauth_request_path(resource,provider)
				resource_or_scope = resource.nil? ? ":res" : 
				resource_pluralized(resource)
				"#{omniauth_prefix_path}/#{resource_or_scope}/#{provider}"
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

			##refresh auth token path
			#def self.refresh_auth_token_path(resource_or_scope)
			#	resource_or_scope = resource_or_scope.nil? ? ":res" : resource_pluralized(resource_or_scope.class.name)
			#	"#{Auth.configuration.mount_path}/#{resource_or_scope}/refresh_token"
			#end


		end
	end

end