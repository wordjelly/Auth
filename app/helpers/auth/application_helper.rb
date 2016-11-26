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

    end



  end

end
