module Auth::Concerns::OmniConcern

  extend ActiveSupport::Concern

  included do
    prepend_before_action :do_before_request, only: [:omni_common]
    attr_accessor :resource
    helper_method :omniauth_failed_path_for
  end

  def passthru
    
  end

  def failure
    ##if the resource is nil in the failure url, it was made so by us after detecting that it was not sent in the callback request.
    
    f = failure_message
    
    if f.blank?
      model = nil
      request.url.scan(/#{Auth.configuration.mount_path}\/(?<model>[a-zA-Z_]+)\/omniauth/) do |ll|
        jj = Regexp.last_match
        model = jj[:model]
      end
      if model == "no_resource"
        f = "No resource was specified in the omniauth callback request."
      else
        f = model
      end
    end   

    respond_to do |format|
        format.json { render json: {"failure_message" => f}, status: :unprocessable_entity }
    end

  end


  def get_omni_hash
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
        
        begin
          model_class = request.env["devise.mapping"]
          if model_class.nil?
           ##COVERED IN #NO_RESOURCE_TEST.
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

              #puts "resource before the update"
              #puts JSON.pretty_generate(@resource.attributes)

              @resource.versioned_update({"access_token" => 1, "token_expires_at" => 1})

              if @resource.op_success
                              
                if !Auth.configuration.auth_resources[request.env["devise.mapping"].to.name][:skip].include? :confirmable
                  @resource.skip_confirmation!
                end
                
                puts("this resource already exists")
                
                sign_in @resource

                redirect_to after_sign_in_path_for(@resource)
                
              else

                #puts "Failed to update the acceess token and token expires at."
                redirect_to omniauth_failed_path_for(resource_klazz.name)

              end

            
            elsif signed_in?

              puts("it is a current user trying to sign up with oauth.")
              
              after_sign_in_path_for(current_res)        

            else 
              
              puts("no such user exists, trying to create a new user by merging the fields.")
                
              
              @resource = resource_klazz.versioned_upsert_one(
                { "$or" => [
                    {"email" => email},
                    {
                      "identities" => {
                        "$elemMatch" => {
                          "uid" => uid,
                          "provider" => provider               
                        }
                      }
                    }
                  ]
                },
                {
                  "$setOnInsert" => {
                    "email" => email,
                    "password" =>  Devise.friendly_token(20),
                    "authentication_token" => build_token(resource_klazz),
                    "access_token" => access_token,
                    "token_expires_at" => token_expires_at,
                    "identities" => [identity.attributes.except("_id")]
                  }
                },
                resource_klazz
              )

              #puts "IDENTITY AND RESOURCE FOLLOW."
              #puts identity.to_s
              #puts @resource.attributes.to_s
             
              if !@resource.nil? && @resource.persisted? && @resource.identities == [identity.attributes.except("_id")]

                #puts "going to after sign in path for."
                @resource.create_client

                @resource.skip_confirmation!
                
                ##call the after_save_callbacks.

                sign_in @resource
                puts "After calling sign in resource -------------------------------------------"
                puts @resource.attributes.to_s
                #u = User.where(:email => @resource.email).first
                #puts u.attributes.to_s
                #redirect_to after_sign_in_path_for(@resource)
                respond_with(@resource, :status => :created, :location => after_sign_in_path_for(@resource))
              else
                puts "came to omniauth failure path."
                redirect_to omniauth_failure_path(resource_klazz.name)
              end

            end

          end
        rescue => e
          puts e.to_s
          redirect_to omniauth_failed_path_for("error") and return
        end
  end

end