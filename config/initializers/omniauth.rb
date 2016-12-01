module SimpleTokenAuthentication
	module Configuration
		mattr_accessor :additional_identifiers
		@@additional_identifiers = {}
	end

	Entity.class_eval do 
		def header_names_for_additional_identifiers
			if additional_identifiers = SimpleTokenAuthentication.additional_identifiers["#{name_underscore}".to_sym]
				#puts additional_identifiers.to_s
				additional_identifiers.map{|c| c = "X-#{name_underscore.camelize}-#{c.to_s.camelize}"}
			end
		end

		def get_additional_identifiers_from_headers(controller)
			Hash[header_names_for_additional_identifiers.map{|c| c = [c,controller.request.headers[c]]}]
		end
	end

	module TokenAuthenticationHandler

		def authenticate_entity_from_token!(entity)
		  ##here we should find the record by the authentication token.
		  ##then we should find
	      record = find_record_from_identifier(entity)

	      if token_correct?(record, entity, token_comparator)
	        perform_sign_in!(record, sign_in_handler)
	      end
	    end

	    def find_record_from_identifier(entity)
	    	token = entity.get_token_from_params_or_headers(self)
		    token && entity.model.find_for_authentication("authentication_token" => token)
	    end

		def token_correct?(record, entity, token_comparator)
      		additional_identifiers = entity.get_additional_identifiers_from_headers(self)
      		
      		identifier_param_value = entity.get_identifier_from_params_or_headers(self).presence

      		identifier_param_value = integrate_with_devise_case_insensitive_keys(identifier_param_value, entity)

      		additional_identifiers.each do |key,value|
      			a = record.client_authentication[value]
      			if !token_comparator.compare(a,identifier_param_value)
      				return false
      			end
      		end
      		return true
    	end
	end

end


module OmniAuth
	module Strategy

		##abilitiy to pass models.
	    ##returns the models that are passed in / for which we are using omniauth.
	    def models
	      options[:models] || OmniAuth.config.models
	    end

		##a modification of the on path method to check if we are on any of the defined request or callback paths.
	    ##tests each of the provided paths to see if we are on it.
	    def on_any_path?(paths)
	      path_found = false
	      paths.each do |path|
	       	path_found = on_path?(path) ? true : path_found
	      end
	      return path_found
	    end


	    def request_paths
	    	paths = []
	  		models.each do |model|
	  			paths << Auth::OmniAuth::Path.omniauth_request_path(model,name)
	  		end		  	
	  		paths
	    end

	    def callback_paths
	    	paths = []
	  		models.each do |model|
	  			paths << Auth::OmniAuth::Path.omniauth_callback_path(model,name)
	  		end		  	
	  		paths
	    end

	    ##THESE ARE THE ONLY TWO METHODS THAT ARE ACTUALLY OVERRIDDEN.
	    def on_request_path?
	    	on_any_path?(request_paths)
	    end

	    ##modified to use Auth::OmniAuth::Path
	    def callback_path
	      @callback_path ||= begin
	        path = options[:callback_path] if options[:callback_path].is_a?(String)
	        path ||= current_path if options[:callback_path].respond_to?(:call) && options[:callback_path].call(env)
	        path ||= custom_path(:request_path)
	        path ||= Auth::OmniAuth::Path.common_callback_path(name)
	        path
	      end
	    end

	    ##request call - modified to setup the model.
	    def request_call
	      setup_phase
	      log :info, 'Request phase initiated.'
	      # store query params from the request url, extracted in the callback_phase
	      session['omniauth.params'] = request.params
	      session['omniauth.model'] = request.url
	      OmniAuth.config.before_request_phase.call(env) if OmniAuth.config.before_request_phase
	      
	      if options.form.respond_to?(:call)
	        log :info, 'Rendering form from supplied Rack endpoint.'
	        options.form.call(env)
	      elsif options.form
	        log :info, 'Rendering form from underlying application.'
	        call_app!
	      else
	        if request.params['origin']
	          env['rack.session']['omniauth.origin'] = request.params['origin']
	        elsif env['HTTP_REFERER'] && !env['HTTP_REFERER'].match(/#{request_path}$/)
	          env['rack.session']['omniauth.origin'] = env['HTTP_REFERER']
	        end
	        request_phase
	      end
	    end

	    ##now the callback call
	    # Performs the steps necessary to run the callback phase of a strategy.
	    def callback_call
	      check_state
	      setup_phase
	      log :info, 'Callback phase initiated.'
	      @env['omniauth.origin'] = session.delete('omniauth.origin')
	      @env['omniauth.origin'] = nil if env['omniauth.origin'] == ''
	      @env['omniauth.params'] = session.delete('omniauth.params') || {}
	      if !session['omniauth.model'].blank?
	      	@env['omniauth.model'] = session.delete('omniauth.model')
	      end

	      OmniAuth.config.before_callback_phase.call(@env) if OmniAuth.config.before_callback_phase
	      callback_phase
	    end


	    def check_state
	    	if !request.params['state'].blank? && JSON.is_json?(request.params['state'])
	    		c = Auth::Client.new(JSON.parse(request.params['state']))
	    		if !Auth::Client.find_valid_api_key(c.api_key).nil?
	    			session['omniauth.state'] = request.params['state'] = c.api_key
	    			@env['omniauth.model'] = c.path
	    		end
	    	end
	    end


	end
end



Rails.application.config.middleware.use OmniAuth::Builder do

	##want to generate a hash that shows:
	##{:user => 'es', :admin => 'es',......other_models => 'es'}
	##this es is the additional identifier in addition to the authentication_token.
	##so it has to be defined for each model.
	##will also need to add app_id, and client id specific shit here.
	
	if Auth.configuration.enable_token_auth
		SimpleTokenAuthentication.configure do |cf|
		  q = Hash[Auth.configuration.auth_resources.keys.map{|c| c = [c.downcase.to_sym,'es']}]
		  cf.identifiers = q
		  q2 = Hash[Auth.configuration.auth_resources.keys.map{|c| c = [c.downcase.to_sym,['aid']]}]
		  cf.additional_identifiers = q2
		end
	end

	
	on_failure { |env| Auth::OmniauthCallbacksController.action(:failure).call(env) }
	
	oauth_credentials = Auth.configuration.oauth_credentials.map{|k,v| [OmniAuth::Utils.camelize(k).downcase, v]}.to_h
	oauth_keys = oauth_credentials.keys


	##determine which models are oauthable, we need to pass this into the builder.
	oauthable_models = Auth.configuration.auth_resources.keys.reject{|m|

		if Auth.configuration.auth_resources[m][:skip].nil?
			false
		elsif (Auth.configuration.auth_resources[m][:skip].include? :omniauthable)
			true
		else
			false
		end
	}


	OmniAuth::Strategies.constants.each do |constant|

		provider_key = constant.to_s.downcase
		
	
		if oauth_keys.include? provider_key

			
			provider(constant.to_s, oauth_credentials[provider_key]["app_id"], oauth_credentials[provider_key]["app_secret"],oauth_credentials[provider_key]["options"].merge!({:path_prefix => Auth::OmniAuth::Path.omniauth_prefix_path, :models => oauthable_models}))

		end


	end

end
