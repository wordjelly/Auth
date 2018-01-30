module Auth::Concerns::DeviseConcern

    extend ActiveSupport::Concern

    included do
		
	    #skip_before_action :verify_authenticity_token, if: :is_json_request?
        protect_from_forgery with: :null_session
        attr_accessor :m_client
    end

    ##returns true if the recaptcha is not specified in the configuration
    ##returns true if the recaptcha is valid.
    ##expects the parameter 'g-recaptcha-response' in the params hash
    ##if the request is json, and has the header os-android, then it will use the android_recaptcha_api_key as the secret key, otherwise will use the default recaptch_secret key that should have been configured in the pre-initializer.
    ##it is currently being called in the registrations_controller on create and update, and in the otp action send_sms_otp,verify_sms_otp.
    ##so all these are protected by recaptcha, but not on iphone.
    def check_recaptcha
    	
    	return true unless Auth.configuration.recaptcha
        
       	recaptcha_options = {}
    	if is_json_request?
    		#puts "is json request."
    		return true unless request.headers["OS-ANDROID"]
    		#puts "android is there in headers."
    		not_found("recaptcha validation error") unless Auth.configuration.third_party_api_keys[:android_recaptcha_secret_key]
    		#puts "android key is there in config."
    		recaptcha_options[:secret_key] = Auth.configuration.third_party_api_keys[:android_recaptcha_secret_key]
    	end
    	#puts "recaptcha_options are : #{recaptcha_options}"
    	not_found("recaptcha validation error") unless verify_recaptcha(recaptcha_options)
    end


	def is_omniauth_callback?	   
	    controller_name == "omniauth_callbacks" 
	end

    def ignore_json_request
      if is_json_request?
        render :nothing => true, :status => 406 and return
      end
    end


    ##SHOULD WE OR NOT DELETE THE CLIENT AND REDIRECT URL?
    ##this was relevant only in the case of oauth visits
    ##suppose someone comes from remote with redir + client.
    ##these get set and stored in the session
    ##then he goes to oauth and comes back.
    ##by this time the instance variables are no more
    ##so we fall back on the session variables and redirect him
    ##the only worry was , that what if someone prompts the user to go to wordjelly with a redirect url of their choice.
    ##so what i do here right now is clear the instance redirect and client vars.
    ##then i set the client, if necessary from the session
    ##but while doing set_redirect_url i give first pref to the redir from the params, and then CHECK whether that is valid against the client already from the sessin.
    ##so basically they cannot be redirected to any url that is not stored against the client.
    ##so they can at the worst be redirected only to a url which was provided during client creation.
    ##so there is no need to delete the client from the session at every request, except if it is a json request.
	def clear_client_and_redirect_url
	    session.delete('omniauth.state')
	    if is_json_request?
	    	session.delete("client")
	    	session.delete("redirect_url")
	    end
	end

    def set_client
	    
	    if session[:client]
	      
	      
	      return true

	    else
	      #puts "params are: #{params.to_s}"
	      state = nil
	      api_key = nil
	      current_app_id = nil
	      path = nil
	      if params[:state] && JSON.is_json?(params[:state])
	        state = JSON.parse(params[:state])
	      end
	      
	      if state
	        api_key = state["api_key"]
	        current_app_id = state["current_app_id"]
	        path = state["path"]
	      elsif params[:api_key] && params[:current_app_id]
	        api_key = params[:api_key]
	        current_app_id = params[:current_app_id]
	      else
	      end
	      
	      if api_key.nil? || current_app_id.nil?
	        
	      else
            #puts "api key:#{api_key}"
            #puts "current app id: #{current_app_id}"

	        if session[:client] = Auth::Client.find_valid_api_key_and_app_id(api_key, current_app_id)
	          	
                request.env["omniauth.model"] = path
                
                self.m_client = Auth::Client.find_valid_api_key_and_app_id(api_key, current_app_id)
                
	          	return true
	        end
	      end
	      return false
	    end
    end

    def is_json_request?

         return (request.format.symbol == :json) ? true : false
    end

	def protect_json_request
	   	##should block any put action on the user
	   	##and should render an error saying please do this on the server.
	    if is_json_request? 
            puts "it is a json request."
	    	if action_name == "otp_verification_result"
	    		##we let this action pass because, we make json ajax requests 
	    		##from the web ui to this endpoint, and anyway it does
	    		##not return anything sensitive.
                #puts "action name is otp verification result."
	    	else
                #puts "action name is something else."
		    	if session[:client].nil?
                    puts "cient is nil so rendering nothing."
		      		render :nothing => true , :status => :unauthorized
		      	else
                    #puts "client is not nil"
                end
	      	end
	    end
	end

    def set_redirect_url
    
        # puts "the params redirect url is: #{params[:redirect_url]}"
        # puts "the session redirect url is: #{session[:redirect_url]}"
        redir_url = params[:redirect_url].nil? ? session[:redirect_url] : params[:redirect_url]

        #puts "redir url was: #{redir_url}"

        #puts "session[:client] is: #{session[:client]}"

        #puts "session[:client].redirect urls"
        #puts session[:client].redirect_urls
        
        #puts "does it contain the redirect url."
        #puts session[:client].contains_redirect_url?(redir_url)
        cli = session[:client]
        cli = Auth::Client.new(session[:client]) if session[:client].is_a? Hash

	    if redir_url && session[:client] && cli.contains_redirect_url?(redir_url) && !(is_json_request?)
	        
	        session[:redirect_url] = redir_url
	        
	    end
  	end

  
    def do_before_request
       puts "came to do before request."
       clear_client_and_redirect_url
   
       set_client
   
       set_redirect_url

       protect_json_request

    end

    ##used only in render, redirect in DeviseController.class_eval
    def current_resource(resource)
        send("current_#{resource.class.name.underscore.downcase}")
    end



end