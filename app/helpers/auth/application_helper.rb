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

    ##devise path helpers
    def profile_res_path
      send "profile_#{current_res.res_name_small}_path"
    end

    def destroy_res_session_path
      send "destroy_#{current_res.res_name_small}_session_path"
    end

    ##SHOULD THE RESOURCE SIGN IN OPTIONS BE SHOWN IN THE NAV BAR?
    def resource_in_navbar?(resource)
      return false unless resource
      return (Auth.configuration.auth_resources[resource.class.name][:nav_bar] && Auth.enable_sign_in_modals)
    end

  end

end
