Rails.application.routes.draw do

  resources :tests
  resources :topics
  
  
  get 'get_activities' , :action => "get_activities", :controller => "activity"


  root "home#index"
  
  mount_routes Auth.configuration.auth_resources
  
  ##app-specific routes 
  namespace :api do 

    namespace :v1 do 

      post "user_info" => 'token_auth#index'

    end

  end

 
end