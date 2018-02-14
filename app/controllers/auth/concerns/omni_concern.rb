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


  def update_identity_information(identity_info,provider)
      @resource.identities.map{|i|
        if(i["provider"] && i["provider"] == provider)
          i["access_token"] = identity_info["access_token"]
          i["token_expires_at"] = identity_info["token_expires_at"]
        end
      }
  end

  ## @return[Boolean] : true if the update was successfull, false otherwise
  ## method from_view is taken from Auth::ApplicationController
  def update_access_token_and_expires_at(existing_oauth_resources,resource_klazz,identity_info,provider)
    @resource = from_view(existing_oauth_resources,resource_klazz)
    @resource.m_client = self.m_client
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
  
  
  ############################################################
  ## Working:
  ## First searches for an account with the oauth identity.
  ## Found : tries to update it with a new access token, failing update -> retursn failure.
  ## Not Found : tries to create an account with the email of the oauth identity, and identities = [oauth_identity]
  ## if op_success : return success
  ##
  ## elsif matched_count == 1 : it means an account already exists with this email . Here there are two possibilities.
  ## a. The earlier account was created by using another oauth provider -> in this case its version will have been set as '1', and we now execute a versioned_update -> pushing in the identity of the other oauth account. Thus two oauth providers are merged into one if they share the same email address.
  ## b. the earlier account was created by the normal sign up process: in this case its version will be '0', the versioned updated to push in the oauth identity will fail. If the earlier account is a confirmed account, error will say accoutn in user, if not, then error will say, "there was some errro..."
  ##
  ## else 
  ## there was no matched count, and op failed, so we return failure.
  ##
  ##
  ## ** To prevent oauth account merger, set the configuration option :prevent_oauth_merger to true, it is false by default.
  ##
  ############################################################
  def omni_common
        
        success = false
        failure = false
        failure_message = "There was an error processing your request"

        begin
          
          model_class = request.env["devise.mapping"]
          if model_class.nil?
          
           redirect_to omniauth_failed_path_for("no_resource"), :notice => "No resource was specified in the omniauth callback request." and return 
          else
            resource_klazz = request.env["devise.mapping"].to
           
            omni_hash = get_omni_hash
            
            puts "the omni hash is:"
            puts omni_hash
            
            identity = Auth::Identity.new.build_from_omnihash(omni_hash)

            ##this index is used for the first query during oauth, to check whether the user already has registered using oauth with us.
            puts "identity is:"
            puts identity
            existing_oauth_resources = 
            resource_klazz.collection.find(
              {"identities" =>
                     {"$elemMatch" => 
                            {"provider" => identity.provider, "uid" => identity.uid}
                     }
              })
              
           

            if existing_oauth_resources.count == 1
              
              puts "found matching identity."
                
              if  update_access_token_and_expires_at(existing_oauth_resources,resource_klazz,identity.attributes.except("_id","provider","uid"),identity.provider)
                 puts "updated access token."     
                 success = true
                  #respond_with @resource, location: after_sign_in_path_for(@resource)               
              else
                  puts "failed to update access token."
                  success = false
                #redirect_to omniauth_failed_path_for(resource_klazz.name),:notice => "Failed to update the acceess token and token expires at"

              end

            
            elsif signed_in?

              puts("it is a current user trying to sign up with oauth.")
              
              after_sign_in_path_for(current_res)        

            else 
              
              puts("no such user exists, trying to create a new user by merging the fields.")
                
              @resource = resource_klazz.new
              @resource.email = identity.email
              @resource.password = Devise.friendly_token(20)
              @resource.regenerate_token
              @resource.identities = [identity.attributes.except("_id")]
              if @resource.respond_to?(:confirmed_at)
                @resource.confirmed_at = Time.now.utc  
              end
                
              ## skip_email_unique_validation is set to true in omni_concern in the situation:
              ##1.there is no user with the given identity.
              ## however it is possible that a user with this email exists.
              ## in that case, if we try to do versioned_create, then the prepare_insert block in mongoid_versioned_atomic, runs validations. these include, checking if the email is unique, and in this case, if a user with this email already exists, then the versioned_create doesnt happen at all. We don't want to first check if there is already an account with this email, and in another step then try to do a versioned_update, because in the time in between another user could be created. So instead we simply just set #skip_email_unique_validation to true, and as a result the unique validation is skipped.
              @resource.skip_email_unique_validation = true
              

              @resource.m_client = self.m_client
              
              ## end.
              @resource.versioned_create({"email" => @resource.email})
              ##reset so that no other issues crop up later.
              @resource.skip_email_unique_validation = false
              
              #puts "@resource email is:"
              #puts @resource.email.to_s              

              if @resource.op_success
                puts "create was successfull"
                  sign_in @resource
                  puts "signed in resource."
                  #respond_with @resource, location: after_sign_in_path_for(@resource)
                   success = true
                    #respond_to do |format|
                    #  format.html { redirect_to after_sign_in_path_for(@resource) and return}
                    #  format.json  { render json: @resource, status: :updated and return}
                    #end      
                    puts "came after the response."

                ##do the update.
              elsif @resource.matched_count == 1
                  #puts "found such a resource."    
                  
                  ## this means a resource with this email account was found.
                  ## if the account is not confirmed, then we can push the identity.
                  ## and we can reset the password.

                  @resource = resource_klazz.where(:email => @resource.email).first
                  @resource.m_client = self.m_client
                  
                  if @resource.confirmed?
                    failure_message = "That email is in use by another account"
                  end

                  if Auth.configuration.prevent_oauth_merger == true

                    success = false
                    
                  else

                    @resource.identities.push(identity.attributes.except("_id"))

                    @resource.versioned_update({"identities" => 1})

                    if @resource.op_success
                      puts "succeeded and signed in user."
                      sign_in @resource
                      
                      success = true

                      #respond_with @resource, location: after_sign_in_path_for(@resource)

                    else
                      puts "op success failure"
                      success = false
                      #redirect_to omniauth_failed_path_for(resource_klazz.name),:notice => "Failed to create new identity"
                    end

                  end
               
              else
                
                puts "resource create failed."
                puts @resource.errors.full_messages.to_s
                success = false
                #redirect_to omniauth_failed_path_for(resource_klazz.name),:notice => "Failed to create new identity"
              end



            end

          end
              
        

        rescue => e
          puts "SOME OTHER ERROR"
          puts e.to_s
          puts e.backtrace
          redirect_to omniauth_failed_path_for("error"), :notice => "error" and return
          success = false
        end

        puts "Success is :#{success.to_s}"

        
          respond_to do |format|
            if success == true
              format.html { redirect_to after_sign_in_path_for(@resource) and return}
              format.json  { render json: @resource, status: :updated and return}
            else
              #@resource.errors.add(:_id,"failed")
              format.html { redirect_to omniauth_failed_path_for(failure_message), :notice => failure_message and return}
              format.json  { render json: {:errors => failure_message}, status: :unprocessible_entity and return}
            end
          end   
        

  end

end