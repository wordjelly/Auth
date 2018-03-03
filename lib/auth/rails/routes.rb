module ActionDispatch::Routing
  class Mapper

  	##@param app_route_resources[Hash] -> 
  	##key:resource[String] -> the name of the resource for which omniauth routes are to be generated.
  	##value:opts[Hash] -> the options specifying the views, controllers etc for omniauth.
  	##expected to be present in the preinitializer in the routes of the target app.
	def mount_routes(app_route_resources)

	      resources :search, :controller => "auth/search" do 
	      	collection do 
	      		get 'authenticated_user_search', :action => 'authenticated_user_search', :as => "authenticated_user"
	      	end
	      end

	      ## this controller may need to be changed, actually will have to be changed for every single thing.
	      resources :assemblies, :controller => Auth.configuration.assembly_controller

	      resources :stages, :controller => Auth.configuration.stage_controller

	      resources :sops, :controller => Auth.configuration.sop_controller

	      resources :steps, :controller => Auth.configuration.step_controller

	      ## image controller is required by default.
	      ## 
	      #resources :images, :controller => Auth.configuration.image_controller

	      resources :admin_create_users, :controller => "auth/admin_create_users"

	  	  resources :clients, :controller => "auth/clients"
		  resources :profiles, :controller => "auth/profiles" do 
		  	collection do 
		  		## :resource will be something like users.
		  		post ':resource/set_proxy_user', :action => 'set_proxy_resource', :as => "set_proxy_resource"
		  		get 'credential_exists', :action => 'credential_exists'
		  		post ':resource/get_user_id', :action => 'get_user_id'
		  		put ':resource/update', :action => 'update'
		  		
		  	end
		  end
		  
		 if Auth.configuration.otp_controller
			 get "#{Auth.configuration.mount_path}/:resource/otp_verification_result", :action => "otp_verification_result", :controller => "#{Auth.configuration.otp_controller}", :as => "otp_verification_result"
			  get "#{Auth.configuration.mount_path}/:resource/verify_otp", :action => "verify_otp", :controller => "#{Auth.configuration.otp_controller}", :as => "verify_otp"
			  get "#{Auth.configuration.mount_path}/:resource/send_sms_otp", :action => "send_sms_otp", :controller => "#{Auth.configuration.otp_controller}", :as => "send_sms_otp"
			  get "#{Auth.configuration.mount_path}/:resource/resend_sms_otp", :action => "resend_sms_otp", :controller => "#{Auth.configuration.otp_controller}", :as => "resend_sms_otp"
		  end


			["cart_item","cart","payment","product","discount","image"].each do |model|

				if Auth.configuration.send("#{model}_controller")

					scope_path = "/"
			 	 	as_prefix = nil
			 	 	collection = nil

			 	 	Auth.configuration.send("#{model}_class").underscore.pluralize.scan(/(?<scope_path>.+?)\/(?<collection>[A-Za-z_]+)$/) do 

			 	 		if Regexp.last_match[:scope_path]
			 	 			scope_path = scope_path +  Regexp.last_match[:scope_path]
			 	 			## this is done so that the route helper defined inside the engine views also work.
			 	 			as_prefix =  Regexp.last_match[:scope_path]
			 	 		end
			 	 		collection = Regexp.last_match[:collection]

			 	 	end

			 	 	if collection
				 	 	scope :path => scope_path, :as => as_prefix do
				 	 		#puts "As prefix is: #{as_prefix}" 
				 	 		#puts "scope path is: #{scope_path}"
				 	 		controller_name = Auth.configuration.send("#{model}_controller")
				 	 		
			 	 			resources collection.to_sym, controller: controller_name do
			 	 				collection do 
			 	 				## for the option to create multiple cart items at one time.
				 	 				if model == "cart_item"
				 	 					post 'create_multiple', :action => 'create_multiple'
				 	 				end
			 	 				end

			 	 			end
				 	 		
					    	
					    	##A ROUTE HAS BEEN ADDED IN THE DAUGHTER APP FOR THE POST -> TO THE PAYMENTS_UPDATE FOR PAYUMONEY.
					    	##refer payumoney_controller_concern.rb
					    end
					end

				end

			end


		  
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
			
              #################################################################
              ##
              ## OMNIAUTH PATHS
              ##
              #################################################################

			  if !(opts[:skip].include? :omniauthable)

					resource_class.omniauth_providers.each do |provider|
						
						omniauth_request_path = Auth::OmniAuth::Path.omniauth_request_path(nil,provider)

						common_callback_path = Auth::OmniAuth::Path.common_callback_path(provider)

						if !Rails.application.routes.url_helpers.method_defined?("#{provider}_omniauth_authorize_path".to_sym)
							puts "calling route for provider: #{provider}"
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

			  #################################################################
			  ##
			  ## RESOURCE_PROFILE PATHS
			  ##
			  #################################################################

			  #match "#{omniauth_request_path}", controller: omniauth_ctrl, action: "passthru", via: [:get,:post], as: "#{provider}_omniauth_authorize"

		  end
	  end
  end
end

