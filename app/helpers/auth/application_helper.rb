module Auth

  module ApplicationHelper

    ##returns the name in small case of the class of the currently signed in resource
    ##@example : will return 'user' or 'admin'
    def get_signed_in_scope
      if signed_in?
        Devise.mappings.keys.each do |res|
          l = send "#{res.to_s}_signed_in?"
          puts l.to_s
          if send "#{res.to_s}_signed_in?"
            return res.to_s
          end
        end
      end
      return nil
    end

    def current_res
      return if get_signed_in_scope.nil?
      send "current_#{get_signed_in_scope}"
    end

    ##@return[String] : downcased current resource name
    def res_name_small
      return unless current_res
      return current_res.class.name.downcase
    end

    ##@return[String] : Upcase current resource name 
    def res_name
      return unless current_res
      return current_res.class.name
    end

    ##SHOULD THE RESOURCE SIGN IN OPTIONS BE SHOWN IN THE NAV BAR?
    def resource_in_navbar?(resource)
      return false unless resource
      return (Auth.configuration.auth_resources[resource.class.name][:nav_bar] && Auth.enable_sign_in_modals)
    end

    ##############################################
    ##
    ## DEVISE PATH HELPERS.
    ## ALL HELPERS USE "RES" , instead of a hardcoded scope like user
    ## 
    ##
    ##############################################
=begin
                new_user_session GET      /authenticate/users/sign_in(.:format)                   auth/sessions#new
                    user_session POST     /authenticate/users/sign_in(.:format)                   auth/sessions#create
            destroy_user_session DELETE   /authenticate/users/sign_out(.:format)                  auth/sessions#destroy
        cancel_user_registration GET      /authenticate/users/cancel(.:format)                    auth/registrations#cancel
               user_registration POST     /authenticate/users(.:format)                           auth/registrations#create
           new_user_registration GET      /authenticate/users/sign_up(.:format)                   auth/registrations#new
          edit_user_registration GET      /authenticate/users/edit(.:format)                      auth/registrations#edit
                                 PATCH    /authenticate/users(.:format)                           auth/registrations#update
                                 PUT      /authenticate/users(.:format)                           auth/registrations#update
                                 DELETE   /authenticate/users(.:format)                           auth/registrations#destroy
                   user_password POST     /authenticate/users/password(.:format)                  auth/passwords#create
               new_user_password GET      /authenticate/users/password/new(.:format)              auth/passwords#new
              edit_user_password GET      /authenticate/users/password/edit(.:format)             auth/passwords#edit
                                 PATCH    /authenticate/users/password(.:format)                  auth/passwords#update
                                 PUT      /authenticate/users/password(.:format)                  auth/passwords#update
               user_confirmation POST     /authenticate/users/confirmation(.:format)              auth/confirmations#create
           new_user_confirmation GET      /authenticate/users/confirmation/new(.:format)          auth/confirmations#new
                                 GET      /authenticate/users/confirmation(.:format)              auth/confirmations#show
                     user_unlock POST     /authenticate/users/unlock(.:format)                    auth/unlocks#create
                 new_user_unlock GET      /authenticate/users/unlock/new(.:format)                auth/unlocks#new
                                 GET      /authenticate/users/unlock(.:format)                    auth/unlocks#show

=end

    def new_res_session_path
      send("new_#{current_res.res_name_small}_session_path")
    end

    def res_session_path
      send("#{current_res.res_name_small}_session_path")
    end

    def destroy_res_session_path
      send "destroy_#{current_res.res_name_small}_session_path"
    end

    

  end

end
