module ActionDispatch::Routing
  class Mapper

	def mount_devise_token_auth_for(resource, opts)
	  
	  # ensure objects exist to simplify attr checks
	  opts[:controllers] ||= {}
	  opts[:skip]        ||= []
	  opts[:at] = "/authenticate"

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

	  resource_as_pluralized_string = resource.pluralize.underscore.gsub('/', '_')

	  devise_for resource_as_pluralized_string.to_sym,
	    :class_name  => resource,
	    :module      => :devise,
	    :path        => "#{opts[:at]}/#{resource_as_pluralized_string}",
	    :controllers => controllers,
	    :skip        => opts[:skip] + [:omniauth_callbacks]


	  resource_class = Object.const_get resource
	  # get namespace name
	  namespace_name = @scope[:as]

	  # clear scope so controller routes aren't namespaced
	  @scope = ActionDispatch::Routing::Mapper::Scope.new(
	      path:         "",
	      shallow_path: "",
	      constraints:  {},
	      defaults:     {},
	      options:      {},
	      parent:       nil
	  )

	  mapping_name = resource.underscore.gsub('/', '_')
	  mapping_name = "#{namespace_name}_#{mapping_name}" if namespace_name
	  devise_scope mapping_name.to_sym do

		  resource_class.omniauth_providers.each do |provider|
		  	
		  	match "#{::OmniAuth.config.path_prefix}/#{resource_as_pluralized_string}/auth/#{provider}", controller: omniauth_ctrl, action: "passthru", via: [:get,:post], as: "#{resource.downcase}_#{provider}_omniauth_authorize"

		  	match "#{opts[:at]}/#{resource_as_pluralized_string}/#{provider}/omniauth_callback", controller: omniauth_ctrl, action: provider, via: [:get,:post], as: "#{resource.downcase}_#{provider}_omniauth_callback"

		  end

	  end


=begin
	  unnest_namespace do
	    # get full url path as if it were namespaced
	    full_path = "#{@scope[:path]}/#{opts[:at]}"

	    # get namespace name
	    namespace_name = @scope[:as]

	    # clear scope so controller routes aren't namespaced
	    @scope = ActionDispatch::Routing::Mapper::Scope.new(
	      path:         "",
	      shallow_path: "",
	      constraints:  {},
	      defaults:     {},
	      options:      {},
	      parent:       nil
	    )

	    mapping_name = resource.underscore.gsub('/', '_')
	    mapping_name = "#{namespace_name}_#{mapping_name}" if namespace_name



	    devise_scope mapping_name.to_sym do
	      # path to verify token validity
	      #get "#{full_path}/validate_token", controller: "#{token_validations_ctrl}", action: "validate_token"

	      # omniauth routes. only define if omniauth is installed and not skipped.

	      if defined?(::OmniAuth) and not opts[:skip].include?(:omniauth_callbacks)
	        match "#{full_path}/failure",             controller: omniauth_ctrl, action: "omniauth_failure", via: [:get]
	        match "#{full_path}/:provider/callback",  controller: omniauth_ctrl, action: "omniauth_success", via: [:get]

	        match "#{Auth.omniauth_prefix}/:provider/callback", controller: omniauth_ctrl, action: "redirect_callbacks", via: [:get, :post]
	        match "#{Auth.omniauth_prefix}/failure", controller: omniauth_ctrl, action: "omniauth_failure", via: [:get, :post]

	        # preserve the resource class thru oauth authentication by setting name of
	        # resource as "resource_class" param
	        match "#{full_path}/:provider", to: redirect{|params, request|
	          # get the current querystring

	          qs = CGI::parse(request.env["QUERY_STRING"])

	          # append name of current resource
	          qs["resource_class"] = [resource]
	          qs["namespace_name"] = [namespace_name] if namespace_name

	          set_omniauth_path_prefix!(Auth.omniauth_prefix)

	          # re-construct the path for omniauth
	          "#{::OmniAuth.config.path_prefix}/#{params[:provider]}?#{{}.tap {|hash| qs.each{|k, v| hash[k] = v.first}}.to_param}"
	        }, via: [:get]
	      end
	    end
	  end
=end
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