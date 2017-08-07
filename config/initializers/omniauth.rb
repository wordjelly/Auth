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
	      ##gets.chomp
	      setup_phase
	      log :info, 'Request phase initiated.'
	      puts request.params.to_s
	      puts request.url.to_s
	      # store query params from the request url, extracted in the callback_phase
	      session['omniauth.params'] = request.params
	      session['omniauth.model'] = request.url
	      OmniAuth.config.before_request_phase.call(env) if OmniAuth.config.before_request_phase
	      puts "Came pa"
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
	      #check_state
	      setup_phase
	      log :info, 'Callback phase initiated.'
	      @env['omniauth.origin'] = session.delete('omniauth.origin')
	      @env['omniauth.origin'] = nil if env['omniauth.origin'] == ''
	      @env['omniauth.params'] = session.delete('omniauth.params') || {}
	      ##FOR THE WEB BASED SYSTEM, remember this was set in the request call.
	      if !session['omniauth.model'].blank?
	      	@env['omniauth.model'] = session.delete('omniauth.model')
	      end
	      OmniAuth.config.before_callback_phase.call(@env) if OmniAuth.config.before_callback_phase
	      callback_phase
	    end
  end
  
end
=begin
module OAuth2Extensions
	def self.included base
		base.class_eval do 
			
		end
	end
end

module FacebookOAuthExtensions
	protected
	def build_access_token
		if request.params["fb_exchange_token"]
			##make the get request.
			verify_exchange_token(request.params["fb_exchange_token"])
		else
			verifier = request.params["code"]
		a_t = client.auth_code.get_token(verifier, {:redirect_uri => callback_url}.merge(token_params.to_hash(:symbolize_keys => true)), deep_symbolize(options.auth_token_params))
			a_t.options.merge!(access_token_options)
		end
	end

	private
	def verify_exchange_token(exchange_token)
		return false unless exchange_token 
	params = {:grant_type => "fb_exchange_token", "fb_exchange_token" => exchange_token}.merge(client.auth_code.client_params)
		a_t = client.get_token(params)
	end

	def with_authorization_code!
		if request.params.key?('code') || request.params.key?('fb_exchange_token')
  		yield
    elsif code_from_signed_request = signed_request_from_cookie && signed_request_from_cookie['code']
      request.params['code'] = code_from_signed_request
      @authorization_code_from_signed_request_in_cookie = true
      # NOTE The code from the signed fbsr_XXX cookie is set by the FB JS SDK will confirm that the identity of the
      #      user contained in the signed request matches the user loading the app.
      original_provider_ignores_state = options.provider_ignores_state
      options.provider_ignores_state = true
      begin
        yield
      ensure
        request.params.delete('code')
        @authorization_code_from_signed_request_in_cookie = false
        options.provider_ignores_state = original_provider_ignores_state
      end
    else
      raise NoAuthorizationCodeError, 'must pass either a `code` (via URL or by an `fbsr_XXX` signed request cookie)'
    end
	end
end

module GoogleOAuthExtensions
		def self.included base 
			base.class_eval do 
				def custom_build_access_token
		    		puts "Came to custome build access token."
		    		access_token =
		    		if verify_id_token(request.params['id_token'])
		    			puts "came to verify_id_token"
		    			#puts "id token was verified."
		    			##in this case the access token is pointless, because we dont really get any kind of access for the api, so we just build a dummy token to satisfy the way this method works, since the method is exepcte to return an access token.
		    			##refer to 
		    			##@link: https://developers.google.com/identity/sign-in/android/backend-auth
		    			##@ref: also refer to the signInActivity.java in the android app, where we pass in 'id_token.'
		    			::OAuth2::AccessToken.new(client,"")
			        elsif request.xhr? && request.params['code']
			          ##THIS IS FOR WEB BASED JAVASCRIPT API.
			          verifier = request.params['code']
			          client.auth_code.get_token(verifier, get_token_options('postmessage'), deep_symbolize(options.auth_token_params || {}))
			        elsif request.params['code'] && request.params['redirect_uri']
			          #puts "came to option 3"
			          puts "CODE AND REDIRECT URL."
			          verifier = request.params['code']
			          redirect_uri = request.params['redirect_uri']
			          client.auth_code.get_token(verifier, get_token_options(redirect_uri), deep_symbolize(options.auth_token_params || {}))
			        elsif verify_token(request.params['access_token'])
			          puts "came to option 4"
			          ::OAuth2::AccessToken.from_hash(client, request.params.dup)
			        else
			        	puts "came to CODE ANALYSIS"
			          	##in this case refer to
			          	##@link: https://developers.google.com/identity/sign-in/android/offline-access
			          	##@ref: also refer to the signInActivity.java in the android app where we pass in 'code'
			          	puts "came to option 5"

			          	verifier = request.params["code"]
			          	client.auth_code.get_token(verifier, get_token_options(callback_url), deep_symbolize(options.auth_token_params))
			        end

			        verify_hd(access_token)
			        access_token
		    	end

		    	def callback_phase # rubocop:disable AbcSize, CyclomaticComplexity, MethodLength, PerceivedComplexity
				
			        error = request.params["error_reason"] || request.params["error"]
			        if error
			          puts "there was already an error."
			          fail!(error, CallbackError.new(request.params["error"], request.params["error_description"] || request.params["error_reason"], request.params["error_uri"]))
			        elsif !options.provider_ignores_state  && (request.params["state"].to_s.empty? || request.params["state"] != session.delete("omniauth.state"))
			          headers = Hash[*env.select {|k,v| k.start_with? 'HTTP_'}
					  .collect {|k,v| [k.sub(/^HTTP_/, ''), v]}
					  .collect {|k,v| [k.split('_').collect(&:capitalize).join('-'), v]}
					  .sort
					  .flatten]
					  if headers["Accept"] == "application/json"
					  	puts "detected as json and came to build access_token."
					  	self.access_token = build_access_token
					  	puts "came past custom build."
				        self.access_token = access_token.refresh! if access_token.expired?
				        puts "Came past access_token."
				        super
					  else
				        fail!(:csrf_detected, CallbackError.new(:csrf_detected, "CSRF detected"))
			          end
			        else
			          self.access_token = custom_build_access_token
			          self.access_token = access_token.refresh! if access_token.expired?
			          super
			        end
			      rescue ::OAuth2::Error, CallbackError => e
			        fail!(:invalid_credentials, e)
			      rescue ::Timeout::Error, ::Errno::ETIMEDOUT => e
			        fail!(:timeout, e)
			      rescue ::SocketError => e
			        fail!(:failed_to_connect, e)
			    end

		    	private 

		    	def verify_id_token(id_token)
		    		
		    		return false unless id_token
		    		raw_response = client.request(:get, 'https://www.googleapis.com/oauth2/v3/tokeninfo',
		                                      params: { id_token: id_token }).parsed
		    		
		        	if raw_response['aud'] == options.client_id || options.authorized_client_ids.include?(raw_response['aud'])
			        	@raw_info ||= raw_response
			        	true
			        else
			        	false
			        end

		    	end 
			end
		end
end

OmniAuth::Strategies::GoogleOauth2.send(:include, OAuth2Extensions)
OmniAuth::Strategies::GoogleOauth2.send(:include, GoogleOAuthExtensions)


#OmniAuth::Strategies::Facebook.send(:include, OAuth2Extensions)
OmniAuth::Strategies::Facebook.send(:include, FacebookOAuthExtensions)
=end

module OmniAuth
  module Strategies
  	OAuth2.class_eval do 
  		def callback_phase # rubocop:disable AbcSize, CyclomaticComplexity, MethodLength, PerceivedComplexity
  			
	        error = request.params["error_reason"] || request.params["error"]
	        if error
	          fail!(error, CallbackError.new(request.params["error"], request.params["error_description"] || request.params["error_reason"], request.params["error_uri"]))
	        elsif !options.provider_ignores_state  && (request.params["state"].to_s.empty? || request.params["state"] != session.delete("omniauth.state"))
	          #puts "STATE ISSUES."
	          headers = Hash[*env.select {|k,v| k.start_with? 'HTTP_'}
			  .collect {|k,v| [k.sub(/^HTTP_/, ''), v]}
			  .collect {|k,v| [k.split('_').collect(&:capitalize).join('-'), v]}
			  .sort
			  .flatten]
			  if headers["Accept"] == "application/json"
			  	self.access_token = build_access_token
		        self.access_token = access_token.refresh! if access_token.expired?
		        super
			  else
			  	#puts "came to csrf detected."
 	          	fail!(:csrf_detected, CallbackError.new(:csrf_detected, "CSRF detected"))
	          end
	        else
	          #puts "didnt have any initial state issues."
	          self.access_token = build_access_token
	          self.access_token = access_token.refresh! if access_token.expired?
	          super
	        end
	      rescue ::OAuth2::Error, CallbackError => e
	        fail!(:invalid_credentials, e)
	      rescue ::Timeout::Error, ::Errno::ETIMEDOUT => e
	        fail!(:timeout, e)
	      rescue ::SocketError => e
	        fail!(:failed_to_connect, e)
	    end
	    
	    protected
	    class CallbackError < StandardError
	        attr_accessor :error, :error_reason, :error_uri

	        def initialize(error, error_reason = nil, error_uri = nil)
	          self.error = error
	          self.error_reason = error_reason
	          self.error_uri = error_uri
	        end

	        def message
	          [error, error_reason, error_uri].compact.join(" | ")
	        end
	     end
  	end
  	Facebook.class_eval do 
  		protected
  		def build_access_token
  			if request.params["fb_exchange_token"]
  				##make the get request.
  				verify_exchange_token(request.params["fb_exchange_token"])
  			else
  				verifier = request.params["code"]
        		a_t = client.auth_code.get_token(verifier, {:redirect_uri => callback_url}.merge(token_params.to_hash(:symbolize_keys => true)), deep_symbolize(options.auth_token_params))
  				a_t.options.merge!(access_token_options)
  				a_t
  			end
  		end

  		private
  		def verify_exchange_token(exchange_token)
  			return false unless exchange_token 
    		params = {:grant_type => "fb_exchange_token", "fb_exchange_token" => exchange_token}.merge({"client_id" => options.client_id, "client_secret" => options.client_secret})
  			a_t = client.get_token(params)
  			a_t
  		end

  		def with_authorization_code!
  			if request.params.key?('code') || request.params.key?('fb_exchange_token')
          		yield
	        elsif code_from_signed_request = signed_request_from_cookie && signed_request_from_cookie['code']
	          request.params['code'] = code_from_signed_request
	          @authorization_code_from_signed_request_in_cookie = true
	          # NOTE The code from the signed fbsr_XXX cookie is set by the FB JS SDK will confirm that the identity of the
	          #      user contained in the signed request matches the user loading the app.
	          original_provider_ignores_state = options.provider_ignores_state
	          options.provider_ignores_state = true
	          begin
	            yield
	          ensure
	            request.params.delete('code')
	            @authorization_code_from_signed_request_in_cookie = false
	            options.provider_ignores_state = original_provider_ignores_state
	          end
	        else
	          raise NoAuthorizationCodeError, 'must pass either a `code` (via URL or by an `fbsr_XXX` signed request cookie)'
	        end
  		end

  	end
    GoogleOauth2.class_eval do 
    	def custom_build_access_token
    		#puts "Came to custome build access token."
    		#puts "is the request xhr?"
    		#puts request.xhr?
    		access_token =
    		if verify_id_token(request.params['id_token'])
    			puts "came to verify_id_token"
    			#puts "id token was verified."
    			##in this case the access token is pointless, because we dont really get any kind of access for the api, so we just build a dummy token to satisfy the way this method works, since the method is exepcte to return an access token.
    			##refer to 
    			##@link: https://developers.google.com/identity/sign-in/android/backend-auth
    			##@ref: also refer to the signInActivity.java in the android app, where we pass in 'id_token.'
    			::OAuth2::AccessToken.new(client,"")
	        elsif request.xhr? && request.params['code']
	          ##THIS IS FOR WEB BASED JAVASCRIPT API.
	          verifier = request.params['code']
	          client.auth_code.get_token(verifier, get_token_options('postmessage'), deep_symbolize(options.auth_token_params || {}))
	        elsif request.params['code'] && request.params['redirect_uri']
	          #puts "came to option 3"
	          puts "CODE AND REDIRECT URL."
	          verifier = request.params['code']
	          redirect_uri = request.params['redirect_uri']
	          client.auth_code.get_token(verifier, get_token_options(redirect_uri), deep_symbolize(options.auth_token_params || {}))
	        elsif verify_token(request.params['access_token'])
	          puts "came to option 4"
	          ::OAuth2::AccessToken.from_hash(client, request.params.dup)
	        else
	        	puts "came to CODE ANALYSIS"
	          	##in this case refer to
	          	##@link: https://developers.google.com/identity/sign-in/android/offline-access
	          	##@ref: also refer to the signInActivity.java in the android app where we pass in 'code'
	          	puts "came to option 5"

	          	verifier = request.params["code"]
	          	client.auth_code.get_token(verifier, get_token_options(callback_url), deep_symbolize(options.auth_token_params))
	        end

	        verify_hd(access_token)
	        access_token
    	end
    	alias_method :build_access_token, :custom_build_access_token


    	private 
    	
    	def verify_id_token(id_token)
    		
    		return false unless id_token
    		raw_response = client.request(:get, 'https://www.googleapis.com/oauth2/v3/tokeninfo',
                                      params: { id_token: id_token }).parsed
    		
        	if raw_response['aud'] == options.client_id || options.authorized_client_ids.include?(raw_response['aud'])
	        	@raw_info ||= raw_response
	        	true
	        else
	        	false
	        end

	        
    	end

    	
    end
  end
end


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
		  puts "the entity is: #{entity.to_s}"
	      record = find_record_from_identifier(entity)
	      puts "record is: #{record}"
	      if token_correct?(record, entity, token_comparator)
	        perform_sign_in!(record, sign_in_handler)
	      end
	    end

	    def find_record_from_identifier(entity)
	    	token = entity.get_token_from_params_or_headers(self)
		    token && entity.model.find_for_authentication("authentication_token" => token)
	    end

		def token_correct?(record, entity, token_comparator)
			return false unless record
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

	
	on_failure { |env|
	  #puts "came to on faliure."
	  #puts JSON.pretty_generate(env)
	 Auth::OmniauthCallbacksController.action(:failure).call(env) }
	
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
		puts "Constant is: #{constant}"
		provider_key = constant.to_s.downcase
		
	
		if oauth_keys.include? provider_key

						
			provider(constant.to_s, oauth_credentials[provider_key]["app_id"], oauth_credentials[provider_key]["app_secret"],oauth_credentials[provider_key]["options"].merge!({:path_prefix => Auth::OmniAuth::Path.omniauth_prefix_path, :models => oauthable_models}))

		end


	end

end
