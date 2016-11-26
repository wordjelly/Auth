module ActionDispatch::Routing
  class Mapper

  	##@param app_route_resources[Hash] -> 
  	##key:resource[String] -> the name of the resource for which omniauth routes are to be generated.
  	##value:opts[Hash] -> the options specifying the views, controllers etc for omniauth.
  	##expected to be present in the preinitializer in the routes of the target app.
	def mount_routes(app_route_resources)
	      
	  	  resources :clients, :controller => "auth/clients"
		  
		  app_route_resources.each do |resource,opts| 

		  	  #puts "resource is : #{resource}"
		  	  #puts "opts are: #{opts}"
			  # ensure objects exist to simplify attr checks
			  opts[:controllers] ||= {}
			  opts[:skip]        ||= []
			  

			  # check for ctrl overrides, fall back to defaults
			  sessions_ctrl          = opts[:controllers][:sessions] || "auth/sessions"
			  registrations_ctrl     = opts[:controllers][:registrations] || "auth/registrations"
			  passwords_ctrl         = opts[:controllers][:passwords] || "auth/passwords"
			  confirmations_ctrl     = opts[:controllers][:confirmations] || "auth/confirmations"
			  omniauth_ctrl          = opts[:controllers][:omniauth_callbacks] || "auth/omniauth_callbacks"
			  unlocks_ctrl 			 = opts[:controllers][:unlocks] || "auth/unlocks"

			  # define devise controller mappings
			  controllers = {:sessions           => sessions_ctrl,
			                 :registrations      => registrations_ctrl,
			                 :passwords          => passwords_ctrl,
			                 :confirmations      => confirmations_ctrl,
			             	 :unlocks  			 => unlocks_ctrl
			             	}

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
		
			  if !(opts[:skip].include? :omniauthable)

					resource_class.omniauth_providers.each do |provider|
						
						omniauth_request_path = Auth::OmniAuth::Path.omniauth_request_path(nil,provider)

						common_callback_path = Auth::OmniAuth::Path.common_callback_path(provider)

						if !Rails.application.routes.url_helpers.method_defined?("#{provider}_omniauth_authorize_path".to_sym)
							match "#{omniauth_request_path}", controller: omniauth_ctrl, action: "passthru", via: [:get,:post], as: "#{provider}_omniauth_authorize"
						end

						if !Rails.application.routes.url_helpers.method_defined?("#{provider}_omniauth_callback_path".to_sym)
							match "#{common_callback_path}", controller: omniauth_ctrl, action: "omni_common", via: [:get,:post], as: "#{provider}_omniauth_callback"
						end
					end

					oauth_failure_route_path = Auth::OmniAuth::Path.omniauth_failure_route_path(nil)

					if !Rails.application.routes.url_helpers.method_defined?("omniauth_failure_path".to_sym)

						match "#{oauth_failure_route_path}", controller: omniauth_ctrl, action: "failure", via:[:get,:post], as: "omniauth_failure"
					end
			  end

		  end
	  end

	#end
	
  end
end

