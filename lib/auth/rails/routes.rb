module ActionDispatch::Routing
  class Mapper
  	def get_scope(model)
 	 	scope_path = "/"
 	 
 	 	Auth.configuration.send("#{model}_class").underscore.pluralize.scan(/(?<scope_path>.+?)\/(?<collection>[A-Za-z_]+)$/) do 
 	 		if Regexp.last_match[:scope_path]
 	 			scope_path = scope_path +  Regexp.last_match[:scope_path]
 	 		end
 	 	end

 	 	#first run cyclically and check if the things change.
 	 	#puts "scope path is: #{scope_path}"
 	 	scope_path

  	end

  	def get_prefix(model)
  		as_prefix = nil
  		Auth.configuration.send("#{model}_class").underscore.pluralize.scan(/(?<scope_path>.+?)\/(?<collection>[A-Za-z_]+)$/) do 
 	 		if Regexp.last_match[:scope_path]
 	 			as_prefix =  Regexp.last_match[:scope_path]
 	 		end
 	 	end
 	 	as_prefix
 	 	#Auth.configuration.send("#{model}_class").underscore.pluralize.gsub("\/","_")
 	 	
  	end

  	## now what flashing?
  	## or what ?
  	## a spec?
  	## okay let me add the images
  	## keep making progress
  	## and then we test it later.
  	## let me write flashing.

  	def get_collection(model)
  		collection = nil
  		Auth.configuration.send("#{model}_class").underscore.pluralize.scan(/(?<scope_path>.+?)\/(?<collection>[A-Za-z_]+)$/) do 
 	 		collection = Regexp.last_match[:collection]
 	 	end
 	 	#puts "collection is :#{collection}"
 	 	collection
  	end

  	## the default is 
  	def get_controller(model)
  		Auth.configuration.send("#{model}_controller") 
  	end

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

	     
	      
	      resources :bar_codes, :controller => "auth/shopping/bar_codes", :only => [:show, :index, :new] 	      

	      ## this controller may need to be changed, actually will have to be changed for every single thing.
	      #resources :assemblies, :controller => Auth.configuration.assembly_controller

	      #resources :stages, :controller => Auth.configuration.stage_controller

	      #resources :sops, :controller => Auth.configuration.sop_controller

	      #resources :steps, :controller => Auth.configuration.step_controller
	      
	      #namespace :workflow do 
	      #	resources :orders, :controller => Auth.configuration.order_controller
	  	  #end

	      #resources :requirements, :controller => Auth.configuration.requirement_controller

	      #resources :states, :controller =>  Auth.configuration.state_controller

	      resources :locations, :controller =>  Auth.configuration.location_controller

	      #resources :schedules, :controller =>  Auth.configuration.schedule_controller

	      #resources :bookings, :controller =>  Auth.configuration.booking_controller

	      #resources :slots, :controller =>  Auth.configuration.slot_controller

	      #resources :overlaps, :controller =>  Auth.configuration.overlap_controller

	      #resources :minutes, :controller =>  Auth.configuration.minute_controller

	      #resources :entities, :controller =>  Auth.configuration.entity_controller

	      #resources :specifications, :controller =>  Auth.configuration.specification_controller

	      ## image controller is required by default.
	      ## 
	      #resources :images, :controller => Auth.configuration.image_controller

	      resources :admin_create_users, :controller => "auth/admin_create_users"

	  	  resources :clients, :controller => "auth/clients", :as => "auth_clients"

	  	  resources :endpoints, :controller => Auth.configuration.endpoint_controller
		 
		  resources :profiles, :controller => Auth.configuration.profiles_controller do 
		  	collection do 
		  		## :resource will be something like users.
		  		put ':resource/set_proxy_user', :action => 'set_proxy_resource', :as => "set_proxy_resource"
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


			#["cart_item","cart","payment","product","discount","place","personality","image","bullet","instruction","communication"].each do |model|
				["image"].each do |model|
				## establish a communication controller, model, views and engine constants with defaults.


				if Auth.configuration.send("#{model}_controller")

			 	 	scope_path = get_scope(model)
			 	 	as_prefix = get_prefix(model)
			 	 	collection = get_collection(model)
			 	 	controller_name = get_controller(model)

			 	 	if collection

			 	 		 
			 	 		if model == "bullet" 
			 	 			 
			 	 			resources collection.to_sym, controller: controller_name, path: "/auth/work/bullets"
			 	 		
			 	 		elsif model == "instruction"
			 	 			
			 	 			resources collection.to_sym, controller: controller_name, path: "/auth/work/instructions"	

			 	 		elsif model == "communication"

			 	 			resources collection.to_sym, controller: controller_name, path: "/auth/work/communications"
			 	 		else
			 	 			scope :path => scope_path, :as => as_prefix do
				 	 		
			 	 			resources collection.to_sym, controller: controller_name do
			 	 					collection do 
			 	 						if ((model == "personality") || (model == "place"))
			 	 							get 'search', :action => 'search'
			 	 						end
			 	 					end
				 	 				collection do 
					 	 				if model == "cart_item"
					 	 					post 'create_multiple', :action => 'create_multiple'
					 	 					post 'create_many_items', :action => 'create_many_items'
					 	 				end
				 	 				end			 	 				
			 	 			end
				 	 	
					    	##A ROUTE HAS BEEN ADDED IN THE DAUGHTER APP FOR THE POST -> TO THE PAYMENTS_UPDATE FOR PAYUMONEY.
					    	##refer payumoney_controller_concern.rb

					   		end
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
							#puts "calling route for provider: #{provider}"
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

