module Auth::Concerns::OmniConcern

  extend ActiveSupport::Concern

  included do
    helper_method :omniauth_failed_path_for
  end

  def passthru
    
  end

  def failure
    #puts "HIT THE FAILURE"
    #set_flash_message :alert, :failure, kind: OmniAuth::Utils.camelize(failed_strategy.name), reason: failure_message
    #puts "this is the failed strategy name: #{failed_strategy.name}"
    #puts "this is the failure message : #{failed_message}"
  end


  def get_omni_hash
    request.env["omniauth.auth"]
  end

  def get_model_class

    model = nil
    
    #path = request.env["omniauth.model"]
    
    #puts "omniauth model is #{path}"

    request.env["omniauth.model"].scan(/omniauth\/(?<model>[a-zA-Z]+)\//) do |ll|
      jj = Regexp.last_match
      model = jj[:model]
    end

    model = model.singularize
    model[0] = model[0].capitalize
    model

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

  def omniauth_failed_path_for
    omniauth_failure_path
  end


  def translation_scope
    'devise.omniauth_callbacks'
  end


  def build_token(user_klazz)
    loop do
        token = SimpleTokenAuthentication::TokenGenerator.instance.generate_token
        break token if (user_klazz.where(authentication_token: token).count == 0)
    end
  end

  def omni_common
        ##clear the omniauth state from the session.
        session.delete('omniauth.state')
        user_klazz = Object.const_get(get_model_class)
        puts "got user class as: #{user_klazz}"
        omni_hash = get_omni_hash

        email,uid,provider = omni_hash["info"]["email"],omni_hash["uid"],omni_hash["provider"]

        ##it will derive the resource class from the omni_hash referrer path.

        identity = Auth::Identity.new(:provider => provider, :uid => uid, :email => email)

        ##this index is used for the first query during oauth, to check whether the user already has registered using oauth with us.
        existing_oauth_users = 
        user_klazz.collection.find(
          {"identities" =>
                 {"$elemMatch" => 
                        {"provider" => provider, "uid" => uid
                        }
                 }
          })
     
        if existing_oauth_users.count == 1

          user = from_view(existing_oauth_users,user_klazz)

          if user.persisted?
            
            if !Auth.configuration.auth_resources[get_model_class][:skip].include? :confirmable
              user.skip_confirmation!
            end
            
            Rails.logger.debug("this user already exists")
            
            sign_in user

            redirect_to after_sign_in_path_for(user)
            
          else
           
            redirect_to omniauth_failed_path_for

          end

        
        elsif current_user

          Rails.logger.debug("it is a current user trying to sign up with oauth.")
          
          after_sign_in_path_for(current_user)        

        else 

          Rails.logger.debug("no such user exists, trying to create a new user by merging the fields.")
            

          new_user = user_klazz.versioned_upsert_one(
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
                "authentication_token" => build_token(user_klazz),
                "es" => Digest::SHA256.hexdigest(SecureRandom.hex(32) + email)
              }
            },
            user_klazz
          )

          ##basically if this is not nil, then 
          
        
          ##sign in and send to the user profiles path.

          if !new_user.nil? && new_user.persisted?

            new_user.create_client

            new_user.skip_confirmation!
            
            ##call the after_save_callbacks.

            sign_in new_user
            redirect_to after_sign_in_path_for(new_user)    
          else
            redirect_to omniauth_failed_path_for
          end

        end

     

  end

end