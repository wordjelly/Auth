module Auth

  module ApplicationHelper

    ##returns the name in small case of the class of the currently signed in resource
    ##@example : will return 'user' or 'admin'
    def get_signed_in_scope
      if signed_in?
        Devise.mappings.keys.each do |res|
          l = send "#{res.to_s}_signed_in?"
          if send "#{res.to_s}_signed_in?"
            return res.to_s
          end
        end
      end
      return 'user'
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
      return (Auth.configuration.auth_resources[resource.class.name][:nav_bar] && Auth.configuration.enable_sign_in_modals)
    end

    ##############################################
    ##
    ## DEVISE PATH HELPERS.
    ## ALL HELPERS USE "RES" , instead of a hardcoded scope like user
    ## 
    ##
    ##############################################


    def new_res_session_path(opts = {})
      send "new_#{res_name_small}_session_path",opts
    end

    def res_session_path(opts = {})
      send "#{res_name_small}_session_path",opts
    end

    def destroy_res_session_path(opts = {})
      send "destroy_#{res_name_small}_session_path",opts
    end

    def cancel_res_registration_path(opts = {})
      send "cancel_#{res_name_small}_registration_path",opts
    end

    def res_registration_path(opts = {})
      send "#{res_name_small}_registration_path",opts
    end

    def new_res_registration_path(opts = {})
      send "new_#{res_name_small}_registration_path",opts
    end

    def edit_res_registration_path(opts = {})
      send "edit_#{res_name_small}_registration_path",opts
    end

    def res_password_path(opts = {})
      send "#{res_name_small}_password_path",opts
    end

    def new_res_password_path(opts = {})
      send "new_#{res_name_small}_password_path",opts
    end

    def edit_res_password_path(opts = {})
      send "edit_#{res_name_small}_password_path",opts
    end

    def res_confirmation_path(opts = {})
      send "#{res_name_small}_confirmation_path",opts
    end

    def new_res_confirmation_path(opts = {})
      send "new_#{res_name_small}_confirmation_path",opts
    end

    def res_unlock_path(opts = {})
      send "#{res_name_small}_unlock_path",opts
    end

    def new_res_unlock_path(opts = {})
      send "new_#{res_name_small}_unlock_path",opts
    end


  end

end
