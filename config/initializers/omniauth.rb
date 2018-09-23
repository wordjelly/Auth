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

	    def on_callback_path?
	      
	      on_path?(callback_path)
	    end

	    def on_path?(path)
	      #puts "current path is: #{current_path}"
	      path_without_extension = current_path.gsub(/\.json/,'')
	      
	      #puts "path without extension is :#{path_without_extension}"
	      path_without_extension.casecmp(path).zero?
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

	      setup_phase
	      
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


	    def call!(env) # rubocop:disable CyclomaticComplexity, PerceivedComplexity
	      
	      unless env['rack.session']
	        error = OmniAuth::NoSessionError.new('You must provide a session to use OmniAuth.')
	        raise(error)
	      end

	      @env = env
	      @env['omniauth.strategy'] = self if on_auth_path?
	      
	      return mock_call!(env) if OmniAuth.config.test_mode
	      return options_call if on_auth_path? && options_request?
	      return request_call if on_request_path? && OmniAuth.config.allowed_request_methods.include?(request.request_method.downcase.to_sym)
	      return callback_call if on_callback_path?
	      return other_phase if respond_to?(:other_phase)
	      @app.call(env)
	    end

  end
  
end




module OmniAuth
  module Strategies
  	OAuth2.class_eval do 
  		def callback_phase # rubocop:disable AbcSize, CyclomaticComplexity, MethodLength, PerceivedComplexity

  			#puts "checking the callback phase -----------------------------------------------"
  			#puts request.inspect.to_s
  			#puts request.params.to_s

	        error = request.params["error_reason"] || request.params["error"]
	        #puts "error : #{error}"
	        if error
	          fail!(error, CallbackError.new(request.params["error"], request.params["error_description"] || request.params["error_reason"], request.params["error_uri"]))
	        elsif !options.provider_ignores_state  && (request.params["state"].to_s.empty? || request.params["state"] != session.delete("omniauth.state"))
	          #puts "STATE ISSUES."
	          #puts "state is detected."
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
	      	puts "invalid creds."
	        fail!(:invalid_credentials, e)
	      rescue ::Timeout::Error, ::Errno::ETIMEDOUT => e
	      	puts "timeout."
	        fail!(:timeout, e)
	      rescue ::SocketError => e
	      	puts "socket error."
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
  		
  		def build_access_token
  			request.body.rewind
  			hash = request.body.read
  			request.body.rewind
          	parsedForm = JSON.parse(hash) unless hash.blank?
          	post_params_fb_exchange_token = nil
          	if parsedForm
          		post_params_fb_exchange_token = parsedForm["fb_exchange_token"]
          	end

  			fb_exchange_token = request.params["fb_exchange_token"] || post_params_fb_exchange_token
  			if fb_exchange_token
  				##make the get request.
  				verify_exchange_token(fb_exchange_token)
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
  			## with facebook it is coming as the params.
  			#puts request.params.inspect
  			request.body.rewind
  			hash = request.body.read
  			request.body.rewind
  			#puts "the hash is:"
  			#puts hash.to_s
          	parsedForm = JSON.parse(hash) unless hash.blank?
          	post_params_fb_exchange_token = nil
          	if parsedForm
          		post_params_fb_exchange_token = parsedForm["fb_exchange_token"]
          	end

  			if request.params.key?('code') || post_params_fb_exchange_token
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
	          raise StandardError, 'must pass either a `code` (via URL or by an `fbsr_XXX` signed request cookie)'
	        end
  		end

  	end

    GoogleOauth2.class_eval do 
    	
    	def custom_build_access_token
    		#puts request.inspect.to_s
    		#this is because of the read happening in that other def.
    		
  			request.body.rewind
  			hash = request.body.read
  			request.body.rewind
          	parsedForm = JSON.parse(hash) unless hash.blank?
          	
          	post_params_id_token = nil
          	post_params_access_token = nil

          	if parsedForm
          		post_params_id_token = parsedForm['id_token']
          		post_params_access_token = parsedForm['access_token']
          	end
    		
    		id_token = request.params['id_token'] || post_params_id_token
    		access_token = request.params['access_token'] || post_params_access_token

    		access_token =
    		if verify_id_token(id_token)
    			## ANDROID APP USES THIS 
    			##in this case the access token is pointless, because we dont really get any kind of access for the api, so we just build a dummy token to satisfy the way this method works, since the method is exepcte to return an access token.
    			##refer to 
    			##@link: https://developers.google.com/identity/sign-in/android/backend-auth
    			##@ref: also refer to the signInActivity.java in the android app, where we pass in 'id_token.'
    			puts "id token is verified."
    			::OAuth2::AccessToken.new(client,"")
	        elsif request.xhr? && request.params['code']
	          ##THIS IS FOR WEB BASED JAVASCRIPT API.
	          puts "web javascript"
	          verifier = request.params['code']
	          client.auth_code.get_token(verifier, get_token_options('postmessage'), deep_symbolize(options.auth_token_params || {}))
	        elsif request.params['code'] && request.params['redirect_uri']
	          ## THIS IS FOR WEB BASED HTML API
	          verifier = request.params['code']
	          redirect_uri = request.params['redirect_uri']
	          #puts "verifier is: #{verifier}"
	          #puts "redirect url is: #{redirect_uri}"
	          #puts "getting token options: #{get_token_options(redirect_uri)}"
	          client.auth_code.get_token(verifier, get_token_options(redirect_uri), deep_symbolize(options.auth_token_params || {}))
	        elsif verify_token(access_token)
	          #puts "came to option 4"
	          #puts "this is the access token passing verified."
	          ::OAuth2::AccessToken.from_hash(client, request.params.dup)
	        else
	        	## ANDROID APP USES THIS IF THE REQUEST IS FOR OFFLINE ACCESS.
	        	##puts "came to CODE ANALYSIS"
	          	##in this case refer to
	          	##@link: https://developers.google.com/identity/sign-in/android/offline-access
	          	##@ref: also refer to the signInActivity.java in the android app where we pass in 'code'
	            ## this callback url has to match the one registerd in the credentials on google oauth console.
	            
	            ## the host name for this is taken from configuration.
	            ## the default is to call the method
	            ## #callback_url -> ref to it in #http://www.rubydoc.info/github/intridea/omniauth-oauth2/OmniAuth/Strategies/OAuth2#callback_url-instance_method
	            ## that method calls 'full_host', but that may be the wrong host, especially in case of above mentioned android issue.
	            ## make sure that the host you specify in Auth.configuration 
	            url_to_pass_as_callback = Auth.configuration.host_name + script_name + callback_path

	            

	          	verifier = request.params["code"]

	          	client.auth_code.get_token(verifier, get_token_options(url_to_pass_as_callback), deep_symbolize(options.auth_token_params))
	        	#client.auth_code.get_token(verifier, get_token_options(url_to_pass_as_callback), deep_symbolize(options.auth_token_params))
	        end

	        verify_hd(access_token)
	        access_token
    	end
    	alias_method :build_access_token, :custom_build_access_token


    	private 
    	
    	def verify_id_token(id_token)
    		#puts "id token is: #{id_token}"
    		return false unless id_token
    		raw_response = client.request(:get, 'https://www.googleapis.com/oauth2/v3/tokeninfo',
                                      params: { id_token: id_token }).parsed
    		

    		#puts "verify id token raw response is:"
    		#puts raw_response
        	if raw_response['aud'] == options.client_id || options.authorized_client_ids.include?(raw_response['aud'])
	        	@raw_info ||= raw_response
	        	#puts "could verify."
	        	true
	        else
	        	#puts "could not verify/"
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

	## had to include option force true because otherwise devise does not throw a 401 if you try to do token_authentication inside a devise controller.
	## took 3 hours to sort this mess out.
	DeviseFallbackHandler.class_eval do 

		def authenticate_entity!(controller, entity)
	      controller.send("authenticate_#{entity.name_underscore}!".to_sym,{:force => true})
	    end

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

	module ActsAsTokenAuthenticatable

		def regenerate_token
			self.authentication_token = generate_authentication_token(token_generator)
	      	raise "please set a field called: encrypted_authentication_token on your user model" unless self.respond_to? :encrypted_authentication_token
	      	self.encrypted_authentication_token = Devise::Encryptor.digest(self.class,self.authentication_token)	
	      	self.authentication_token_expires_at = Time.now.to_i + Auth.configuration.token_regeneration_time
		end

		## CHANGE THE AUTHENTICATION TOKEN WHENEVER THE USER IS SAVED. IT DOESNT MATTER IF THERE IS AN EXISTING AUTHENTICATION TOKEN OR NOT.
	    def ensure_authentication_token
	      regenerate_token
	    end
	end

	module TokenAuthenticationHandler

		## here added the first line, so that it doesnt do any fallback in case we are already signed in.
		## this needed to be done, in case for example:
		## there are two models for which authentication is being done.
		## first one authenticates,
		## but then the gem attempts authentication of the second model also, and failing that, triggers the not authenticated fallback.
		## to prevent that from happening, we ignore the fallback if we are already signed in.
		def fallback!(entity, fallback_handler)
		 
      	  return if self.signed_in?

	      fallback_handler.fallback!(self, entity)
	    end

		##how the token authentication works:
		##the function regenerate_token is called whenever a change is made to the email/password/additional_login_param
		##this sets a new authentication_token and also makes the expires at now + 1.day(default)
		##when you try to sign in with tokens, if the token has expired, then regenerate_token is called, and then the record is saved.
		##as a result a new token is generated.
		##this will only happen at the first token auth attempt with expired tokens, because on the subsequenty try, the record will not be found(since the auth token will have changed)
		##thereafter signinng in to the accoutn with the username and password,(by json/or by web if using a redirect_url which is valid), will return the auth token and es.
		##this can then be used to sign in.
		##token_correct function was modified to check additional parameters that maybe used for token auth.
		##for the moment these are X-App-Id, and X-Es, dont yet know how I defined these.
		def authenticate_entity_from_token!(entity)
		  ##here we should find the record by the authentication token.
		  ##then we should find
		  
	      record = find_record_from_identifier(entity)
	      #puts "record found is: #{record.to_s}"
	      
	      if token_correct?(record, entity, token_comparator)
	      	#puts "token is correct." 
	      	return false if record.token_expired?
	      	#puts "token is not expired."
	        #puts "record is:"
	        #puts record.attributes.to_s
	        #puts "is it valid"
	        #puts record.valid?
	        res = perform_sign_in!(record, sign_in_handler)
	      	
	      else
	      	#puts "the token was not correct.-------------------------"
	      end
	    end

	    def find_record_from_identifier(entity)
	    	## you are supposed to find the record using one of the other parameters.
	    	#puts "came to find entity from identifier -----------------------------------"
	    	additional_identifiers = entity.get_additional_identifiers_from_headers(self)
      		
      		#puts "additional_identifiers"
      		#puts additional_identifiers
	    	
	    	app_id_value = additional_identifiers["X-User-Aid"]
	    	user_es_value = additional_identifiers["X-User-Es"]
	    	token = entity.get_token_from_params_or_headers(self)
		   	
		   	#puts "token:#{token}"

		    if token
		    	
		    	## fails if the app id or user es is nil blank or empty
		    	#puts "returning nil"
		    	#puts "app id vlue is:"
		    	#puts app_id_value.to_s
		    	#puts "user es value is:"
		    	#puts user_es_value.to_s
		    	return nil if (app_id_value.blank? || user_es_value.blank?)
		    		
		    	## sanitize the values incoming to leave only letters and numbers.

		    	app_id_value = app_id_value.gsub(/[^0-9a-z]/i, '')
	    		
	    		user_es_value = user_es_value.gsub(/[^0-9a-z]/i, '')
	    		
	    		## fails if there are no alphanumeric characters left in the string.
	    		#puts "the user es vale is: #{user_es_value}"
	    		#puts "user app id id: #{app_id_value}"
	    		return nil if(app_id_value.length == 0 || user_es_value.length == 0)

	    		#puts "app id value is: #{app_id_value}"
	    		#puts "user es value : #{user_es_value}"
	    		#puts "entity model is :#{entity.model}"

	    		#puts "searching for:"
	    		query = {"client_authentication.#{app_id_value}" => user_es_value}

	    		#puts query.to_s

		    	records = entity.model.where(query)
		    	
		    	if records.size > 0
		    		#puts "the records size is:" 
		    		#puts records.size.to_s
		    		#puts "found such a record.!!!!!!!!!!!!"
		    		r = records.first
		    		#puts r.attributes.to_s
		    		return records.first
		    	else
		    		return nil
		    	end
		    end
		    return nil
	    end

		def token_correct?(record, entity, token_comparator)
			return false unless record
			token = entity.get_token_from_params_or_headers(self)
			Devise::Encryptor.compare(record.class,record.encrypted_authentication_token,token)
    	end
	end

end


Rails.application.config.middleware.use OmniAuth::Builder do

	if Auth.configuration

		##want to generate a hash that shows:
		##{:user => 'es', :admin => 'es',......other_models => 'es'}
		##this es is the additional identifier in addition to the authentication_token.
		##so it has to be defined for each model.
		##will also need to add app_id, and client id specific shit here.
		if Auth.configuration.enable_token_auth
			SimpleTokenAuthentication.configure do |cf|
			  #q = Hash[Auth.configuration.auth_resources.keys.map{|c| c = [c.downcase.to_sym,'es']}]
			  #cf.identifiers = q
			  q2 = Hash[Auth.configuration.auth_resources.keys.map{|c| c = [c.downcase.to_sym,['aid','es']]}]
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
			#puts "Constant is: #{constant}"
			provider_key = constant.to_s.downcase
			
		
			if oauth_keys.include? provider_key

							
				provider(constant.to_s, oauth_credentials[provider_key]["app_id"], oauth_credentials[provider_key]["app_secret"],oauth_credentials[provider_key]["options"].merge!({:path_prefix => Auth::OmniAuth::Path.omniauth_prefix_path, :models => oauthable_models}))

			end


		end

	end

end
