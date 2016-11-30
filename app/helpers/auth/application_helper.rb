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

    ##check whether the access token is invalid.
    ##if there is no token_expired value, then it is false, 
    ##
=begin
    def access_token_expired?

    ##if it is omniauthable.
      if !current_res.nil? && !Auth.configuration.auth_resources[current_res.name][:skip].include? :omniauthable

        resource.token_expired.nil? ? false : resource.token_expired
        
      end
  
    end
=end
  end

end
