module Auth::Concerns::OmniConcern

  extend ActiveSupport::Concern

  included do
    attr_accessor :resource
    ##the omniauth access token is to be stored on the user.
    helper_method :omniauth_failed_path_for
  end

  #################COMMUNICATION BETWEEN OUR SERVER AND OAUTH BACKENDS
  

  #################ENDS.


  def passthru
    
  end

  def failure
    ##if the resource is nil in the failure url, it was made so by us after detecting that it was not sent in the callback request.
    if failure_message.blank?
      model = nil
      request.url.scan(/#{Auth.configuration.mount_path}\/(?<model>[a-zA-Z_]+)\/omniauth/) do |ll|
        jj = Regexp.last_match
        model = jj[:model]
      end
      if model == "no_resource"
        failure_message = "No resource was specified in the omniauth callback request."
      end

    end   

  end


  def get_omni_hash
    puts request.env["omniauth.auth"]
    request.env["omniauth.auth"]
  end

  

  def failed_strategy
    request.respond_to?(:get_header) ? request.get_header("omniauth.error.strategy") : env["omniauth.error.strategy"]
  end

  def failure_message
    exception = request.respond_to?(:get_header) ? request.get_header("omniauth.error") : env["omniauth.error"]
    error   = exception.error_reason if exception.respond_to?(:error_reason)
    error ||= exception.error        if exception.respond_to?(:error)
    error ||= (request.respond_to?(:get_header) ? request.get_header("omniauth.error.type") : env["omniauth.error.type"]).to_s
    error.to_s.humanize if error
  end

  def after_omniauth_failure_path_for(scope)
    new_session_path(scope)
  end

  def omniauth_failed_path_for(res)
    omniauth_failure_path(res)
  end


  def translation_scope
    'devise.omniauth_callbacks'
  end




  def build_token(resource_klazz)
    loop do
        token = SimpleTokenAuthentication::TokenGenerator.instance.generate_token
        break token if (resource_klazz.where(authentication_token: token).count == 0)
    end
  end

  def set_access_token_and_expires_at(access_token,token_expires_at)
      @resource.access_token = access_token
      @resource.token_expires_at = token_expires_at
  end

  def omni_common
        ##clear the omniauth state from the session.
        session.delete('omniauth.state')
        ##this is set in the devise.rb initializer, in the before_action under devise controller, which checks if it is the omniauth_callbacks controller.
        model_class = request.env["devise.mapping"]
        if model_class.nil?
         redirect_to omniauth_failed_path_for("no_resource") and return 
        else
          resource_klazz = request.env["devise.mapping"].to
          
          omni_hash = get_omni_hash

          email,uid,provider,access_token,token_expires_at = omni_hash["info"]["email"],omni_hash["uid"],omni_hash["provider"],omni_hash["credentials"]["token"],omni_hash["credentials"]["expires_at"]


          ##it will derive the resource class from the omni_hash referrer path.

          identity = Auth::Identity.new(:provider => provider, :uid => uid, :email => email)

          ##this index is used for the first query during oauth, to check whether the user already has registered using oauth with us.
          existing_oauth_resources = 
          resource_klazz.collection.find(
            {"identities" =>
                   {"$elemMatch" => 
                          {"provider" => provider, "uid" => uid
                          }
                   }
            })
       
          if existing_oauth_resources.count == 1

            @resource = from_view(existing_oauth_resources,resource_klazz)

            set_access_token_and_expires_at(access_token,token_expires_at)

            @resource.versioned_update({"access_token" => 1, "token_expires_at" => 1})


            if @resource.op_success
              
              
              if !Auth.configuration.auth_resources[request.env["devise.mapping"].to.name][:skip].include? :confirmable
                @resource.skip_confirmation!
              end
              
              Rails.logger.debug("this resource already exists")
              
              sign_in @resource

              redirect_to after_sign_in_path_for(@resource)
              
            else
             
              redirect_to omniauth_failed_path_for(resource_klazz.name)

            end

          
          elsif signed_in?

            Rails.logger.debug("it is a current user trying to sign up with oauth.")
            
            after_sign_in_path_for(current_res)        

          else 

            Rails.logger.debug("no such user exists, trying to create a new user by merging the fields.")
              
            
            @resource = resource_klazz.versioned_upsert_one(
              {
                "email" => email,
                "identities" => {
                  "$elemMatch" => {
                    "uid" => {
                      "$ne" => uid
                    },
                    "provider" => {
                      "$ne" => provider
                    }               
                  }
                }
              },
              {
                "$push" => {
                  "identities" => identity.attributes.except("_id")
                },
                "$setOnInsert" => {
                  "email" => email,
                  "password" =>  Devise.friendly_token(20),
                  "authentication_token" => build_token(resource_klazz),
                  "es" => Digest::SHA256.hexdigest(SecureRandom.hex(32) + email),
                  "access_token" => access_token,
                  "token_expires_at" => token_expires_at
                }
              },
              resource_klazz
            )

            ##basically if this is not nil, then 
            
            ##sign in and send to the user profiles path.

            if !@resource.nil? && @resource.persisted?

              @resource.create_client

              @resource.skip_confirmation!
              
              ##call the after_save_callbacks.

              sign_in @resource
              redirect_to after_sign_in_path_for(@resource)    
            else
              redirect_to omniauth_failure_path(resource_klazz.name)
            end

          end

        end
  end

end