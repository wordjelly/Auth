module Auth::Concerns::OmniConcern

  extend ActiveSupport::Concern

  included do
    prepend_before_action :set_devise_mapping_for_omniauth, only: [:omni_common]
    prepend_before_action :do_before_request, only: [:omni_common]
    attr_accessor :resource
    helper_method :omniauth_failed_path_for
  end

  def set_devise_mapping_for_omniauth
    model = nil
    if !request.env["omniauth.model"].blank?
      request.env["omniauth.model"].scan(/omniauth\/(?<model>[a-zA-Z]+)\//) do |ll|
        jj = Regexp.last_match
        model = jj[:model]
      end
      model = model.singularize
      request.env["devise.mapping"] = Devise.mappings[model.to_sym]
    end
  end

  def passthru
    
  end

  def failure
    f = failure_message
    flash[:omniauth_error] = f.blank? ? notice : f
    respond_to do |format|
        format.json { render json: {"failure_message" => flash[:omniauth_error]}, status: :unprocessible_entity}
        format.html { render "auth/omniauth_callbacks/failure.html.erb" }
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

  ## @return[Boolean] : true if the update was successfull, false otherwise
  def update_access_token_and_expires_at(existing_oauth_resources,resource_klazz,access_token,token_expires_at)
    @resource = from_view(existing_oauth_resources,resource_klazz)

    set_access_token_and_expires_at(access_token,token_expires_at)

    @resource.versioned_update({"access_token" => 1, "token_expires_at" => 1})

    if @resource.op_success
                    
      if !Auth.configuration.auth_resources[request.env["devise.mapping"].to.name][:skip].include? :confirmable
        @resource.skip_confirmation!
      end
                      
      sign_in @resource

      true
      
    else


      false

    end
  end
 
  def omni_common
        
        #begin
          
          model_class = request.env["devise.mapping"]
          if model_class.nil?
          
           redirect_to omniauth_failed_path_for("no_resource"), :notice => "No resource was specified in the omniauth callback request." and return 
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
                            {"provider" => provider, "uid" => uid}
                     }
              })
              
           

            if existing_oauth_resources.count == 1
              puts "------THERE ARE EXISTING OAUTH RESOURCES---------"
                
              if  update_access_token_and_expires_at(existing_oauth_resources,resource_klazz,access_token,token_expires_at)

                 respond_to do |format|
                    format.html { redirect_to after_sign_in_path_for(@resource) and return}
                    format.json  { render json: @resource, status: :updated and return}
                 end

              else
                
                redirect_to omniauth_failed_path_for(resource_klazz.name),:notice => "Failed to update the acceess token and token expires at"

              end

            
            elsif signed_in?

              #puts("it is a current user trying to sign up with oauth.")
              
              after_sign_in_path_for(current_res)        

            else 
              
              puts("no such user exists, trying to create a new user by merging the fields.")
                
              @resource = resource_klazz.new
              @resource.email = email
              @resource.password = Devise.friendly_token(20)
              @resource.authentication_token = build_token(resource_klazz)
              @resource.access_token = access_token
              @resource.token_expires_at = token_expires_at
              @resource.identities = [identity.attributes.except("_id")]

              @resource.versioned_create({"email" => @resource.email})

              if @resource.op_success

              else
                ##try the update
                ##FOR TWO OMNIAUTH ACCOUNTS WITH THE SAME EMAIL.
                ##here we are creating the second one.
                ##NEED TO SHIFT ACCESS_TOKEN AND TOKEN_EXPIRES_AT TO THE IDENTITY, SINCE IT IS UNIQUE TO THE IDNETITY.
                @resource = resource_klazz.where(:email => @resource.email).first
                ##check if the id
                @resource.identities.push(identity.attributes.except("_id"))
                @resource.access_token = access_token
                @resource.token_expires_at = token_expires_at
                @resource.versioned_update({"access_token" => 1, "token_expires_at" => 1, "identities" => 1})
                if @resource.op_success
                  sign_in @resource
                  respond_to do |format|
                    format.html { redirect_to after_sign_in_path_for(@resource) and return}
                    format.json  { render json: @resource, status: :updated and return}
                  end
                end
              end


              @resource = resource_klazz.versioned_upsert_one(
                { 
                    "email" => email
                },
                {
                  "$setOnInsert" => {
                    "email" => email,
                    "password" =>  Devise.friendly_token(20),
                    "authentication_token" => build_token(resource_klazz)
                  },
                   "$set" => {
                    "access_token" => access_token,
                    "token_expires_at" => token_expires_at,
                    "identities" => [identity.attributes.except("_id")]
                  }
                },
                resource_klazz
              )
              

              if @resource && @resource.persisted? && @resource.identities == [identity.attributes.except("_id")]

                #puts "going to after sign in path for."
                @resource.create_client

                @resource.skip_confirmation!
                
                ##call the after_save_callbacks.

                sign_in @resource
                puts "After calling sign in resource -------------------------------------------"
               
                respond_to do |format|
                  format.html { redirect_to after_sign_in_path_for(@resource) and return}
                  format.json  { render json: @resource, status: :created and return}
                end
              else
                puts "failed to create new user."
                puts "resource_klazz is: #{resource_klazz.name}"
                redirect_to omniauth_failure_path(resource_klazz.name), :notice => "Failed to create new user"
              end

            end

          end
              
        

        #rescue => e
        #  puts e.to_s
        #  redirect_to omniauth_failed_path_for("error"), :notice => "error" and return
        #end
  end

end