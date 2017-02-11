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

  def update_identity_information(identity_info,provider)
      @resource.identities.map{|i|
        if(i["provider"] && i["provider"] == provider)
          i["access_token"] = identity_info["access_token"]
          i["token_expires_at"] = identity_info["token_expires_at"]
        end
      }
  end

  ## @return[Boolean] : true if the update was successfull, false otherwise
  def update_access_token_and_expires_at(existing_oauth_resources,resource_klazz,identity_info,provider)
    @resource = from_view(existing_oauth_resources,resource_klazz)

    ##identity_info should be a key -> value hash, 
    update_identity_information(identity_info,provider)

    @resource.versioned_update({"identities" => 1})

    if @resource.op_success
                                        
      sign_in @resource

      true
      
    else


      false

    end
  end
 
  def omni_common
        
        begin
          
          model_class = request.env["devise.mapping"]
          if model_class.nil?
          
           redirect_to omniauth_failed_path_for("no_resource"), :notice => "No resource was specified in the omniauth callback request." and return 
          else
            resource_klazz = request.env["devise.mapping"].to
           
            omni_hash = get_omni_hash
            
            
            identity = Auth::Identity.new.build_from_omnihash(omni_hash)

            ##this index is used for the first query during oauth, to check whether the user already has registered using oauth with us.
            #puts "identity is:"
            #puts identity
            existing_oauth_resources = 
            resource_klazz.collection.find(
              {"identities" =>
                     {"$elemMatch" => 
                            {"provider" => identity.provider, "uid" => identity.uid}
                     }
              })
              
           

            if existing_oauth_resources.count == 1
              
                
              if  update_access_token_and_expires_at(existing_oauth_resources,resource_klazz,identity.attributes.except("_id","provider","uid"),identity.provider)

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
              @resource.email = identity.email
              @resource.password = Devise.friendly_token(20)
              @resource.authentication_token = build_token(resource_klazz)
              @resource.identities = [identity.attributes.except("_id")]
              if @resource.respond_to?(:confirmed_at)
                @resource.confirmed_at = Time.now.utc  
              end
              @resource.versioned_create({"email" => @resource.email})

              if @resource.op_success

                ##do the update.
                if @resource.matched_count == 1
                  
                  ##try the update
                  ##FOR TWO OMNIAUTH ACCOUNTS WITH THE SAME EMAIL.
                  ##here we are creating the second one.
                  ##NEED TO SHIFT ACCESS_TOKEN AND TOKEN_EXPIRES_AT TO THE IDENTITY, SINCE IT IS UNIQUE TO THE IDNETITY.
                  @resource = resource_klazz.where(:email => @resource.email).first
                  ##check if the id
                  @resource.identities.push(identity.attributes.except("_id"))
                  @resource.versioned_update({"identities" => 1})
                  if @resource.op_success
                    sign_in @resource
                    respond_to do |format|
                      format.html { redirect_to after_sign_in_path_for(@resource) and return}
                      format.json  { render json: @resource, status: :updated and return}
                    end
                  else
                    redirect_to omniauth_failed_path_for(resource_klazz.name),:notice => "Failed to create new identity"
                  end
                ##create was successfull.
                elsif @resource.upserted_id 
                  
                  sign_in @resource
                  puts "came after sign in resource."
                  puts @resource.errors.full_messages.to_s
                    respond_to do |format|
                      format.html { redirect_to after_sign_in_path_for(@resource) and return}
                      format.json  { render json: @resource, status: :updated and return}
                    end                
                end
              
              else
                puts "THERE WAS NO UPSERTED ID EITHER."
                redirect_to omniauth_failed_path_for(resource_klazz.name),:notice => "Failed to create new identity"
              end


            end

          end
              
        

        rescue => e
          puts e.to_s
          puts e.backtrace
          redirect_to omniauth_failed_path_for("error"), :notice => "error" and return
        end
  end

end