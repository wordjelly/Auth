module ActionDispatch::Routing
  class Mapper

  	##@param app_route_resources[Hash] -> 
  	##key:resource[String] -> the name of the resource for which omniauth routes are to be generated.
  	##value:opts[Hash] -> the options specifying the views, controllers etc for omniauth.
  	##expected to be present in the preinitializer in the routes of the target app.
	def mount_routes(app_route_resources)
	  
	  app_route_resources.each do |resource,opts| 

	  	  puts "resource is : #{resource}"
	  	  puts "opts are: #{opts}"

		  # ensure objects exist to simplify attr checks
		  opts[:controllers] ||= {}
		  opts[:skip]        ||= []
		  

		  # check for ctrl overrides, fall back to defaults
		  sessions_ctrl          = opts[:controllers][:sessions] || "auth/sessions"
		  registrations_ctrl     = opts[:controllers][:registrations] || "auth/registrations"
		  passwords_ctrl         = opts[:controllers][:passwords] || "auth/passwords"
		  confirmations_ctrl     = opts[:controllers][:confirmations] || "auth/confirmations"
		  token_validations_ctrl = opts[:controllers][:token_validations] || "auth/token_validations"
		  omniauth_ctrl          = opts[:controllers][:omniauth_callbacks] || "auth/omniauth_callbacks"

		  # define devise controller mappings
		  controllers = {:sessions           => sessions_ctrl,
		                 :registrations      => registrations_ctrl,
		                 :passwords          => passwords_ctrl,
		                 :confirmations      => confirmations_ctrl}

		  # remove any unwanted devise modules
		  opts[:skip].each{|item| controllers.delete(item)}

		  resource_as_pluralized_string = Auth::OmniAuth::Path.resource_pluralized(resource)

		  devise_for resource_as_pluralized_string.to_sym,
		    :class_name  => resource,
		    :module      => :devise,
		    :path        => "#{Auth::OmniAuth::Path.resource_path(resource)}",
		    :controllers => controllers,
		    :skip        => opts[:skip] + [:omniauth_callbacks]


		  resource_class = Object.const_get resource

		  ##now we have to see if omniauth is defined on the said resource or not.

		  # get namespace name
		  # namespace_name = @scope[:as]

		  # clear scope so controller routes aren't namespaced
		  #@scope = ActionDispatch::Routing::Mapper::Scope.new(
		  #    path:         "",
		  #    shallow_path: "",
		  #    constraints:  {},
		  #    defaults:     {},
		  #    options:      {},
		  #    parent:       nil
		  #)

		  #mapping_name = resource.underscore.gsub('/', '_')
		  #mapping_name = "#{namespace_name}_#{mapping_name}" if namespace_name
		 	
		 	if !(opts[:skip].include? :omniauthable)

				resource_class.omniauth_providers.each do |provider|
					
					puts "resource is: #{resource}"
					puts "provider is: #{provider}"

					request_path = Auth::OmniAuth::Path.omniauth_request_path(resource,provider)

					common_callback_path = Auth::OmniAuth::Path.common_callback_path(provider)

					match "#{request_path}", controller: omniauth_ctrl, action: "passthru", via: [:get,:post], as: "#{provider}_omniauth_authorize"

					match "#{common_callback_path}", controller: omniauth_ctrl, action: "omni_common", via: [:get,:post], as: "#{provider}_omniauth_callback"
				end


				##add the omniauth_sign_in_failed_path.
				oauth_failure_path = Auth::OmniAuth::Path.omniauth_failure_path
				match "#{oauth_failure_path}", controller: omniauth_ctrl, action: "failure", via:[:get,:post], as: "omniauth_failure"

			end


	  end

	end

	# this allows us to use namespaced paths without namespacing the routes
	def unnest_namespace
	  current_scope = @scope.dup
	  yield
	ensure
	  @scope = current_scope
	end

	# ignore error about omniauth/multiple model support
	def set_omniauth_path_prefix!(path_prefix)
	  ::OmniAuth.config.path_prefix = path_prefix
	end

  end
end

