Rails.application.routes.draw do

  resources :oauth_tests do 
    collection do 
      get :google_sign_in
    end
  end
  
  root "home#index"
  mount Auth::Engine => "/authenticate", :as => 'auth'
  mount_routes Auth.configuration.auth_resources
  
  ##app-specific routes 
  namespace :api do 

    namespace :v1 do 

      post "user_info" => 'token_auth#index'

    end

  end

end