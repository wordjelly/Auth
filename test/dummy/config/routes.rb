Rails.application.routes.draw do
  mount Auth::Engine => Auth.configuration.mount_path
  mount_routes Auth.configuration.auth_resources
  
  ##app-specific routes 
  namespace :api do 

    namespace :v1 do 

      post "user_info" => 'token_auth#index'

    end

  end

end