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
	    		if Auth::Client.where(:api_key => c.api_key).count == 1
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
	if Auth.configuration.enable_token_auth
		SimpleTokenAuthentication.configure do |cf|
		  q = Hash[Auth.configuration.auth_resources.keys.map{|c| c = [c.downcase.to_sym,'es']}]
		  cf.identifiers = q
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
