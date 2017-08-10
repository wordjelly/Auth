module Auth::Concerns::DeviseConcern

    extend ActiveSupport::Concern

    included do
		
	    skip_before_action :verify_authenticity_token, if: :is_json_request?
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

	    @client = nil
	    @redirect_url = nil
	    session.delete('omniauth.state')
	    if is_json_request?
	    	session.delete("client")
	    	session.delete("redirect_url")
	    end
	end

    def set_client
	    
	    if session[:client]
	      #puts "GOT SESSION CLIENT."
	      #puts session[:client].to_s
	      #if session[:client].is_a?Hash
	      #   #puts "its a hash."
	      #   @client = Auth::Client.new(session[:client])
	      
	      #elsif session[:client].is_a? Auth::Client
	         #puts "its a client."
	      #   @client = session[:client]
	      #end 
	      
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
	        if session[:client] = Auth::Client.find_valid_api_key_and_app_id(api_key, current_app_id)
	          request.env["omniauth.model"] = path
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
	    
	    if is_json_request? && session[:client].nil?
	      
	      render :nothing => true , :status => :unauthorized

	    end
	end

    def set_redirect_url
    
        # puts "the params redirect url is: #{params[:redirect_url]}"
        # puts "the session redirect url is: #{session[:redirect_url]}"
        redir_url = params[:redirect_url].nil? ? session[:redirect_url] : params[:redirect_url]

	    if redir_url && session[:client] && client.contains_redirect_url?(redir_url) && !(is_json_request?)
	        #puts "came to assign redir url:"
	        #@redirect_url = redir_url
	        session[:redirect_url] = redir_url
	        #puts "#{@redirect_url}"
	    end
  	end

  
    def do_before_request
    
       clear_client_and_redirect_url
   
       set_client
   
       set_redirect_url

       protect_json_request
    
    end



end