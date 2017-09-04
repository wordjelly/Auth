Rails.application.routes.default_url_options[:host] = 'localhost:3000'
Rails.application.routes.draw do

  resources :tests
  resources :topics
  
  
  get 'get_activities' , :action => "get_activities", :controller => "activity"


  root "home#index"
  
  mount_routes Auth.configuration.auth_resources
    

  ##PAYUMONEY CALLBACK ROUTE
  post 'shopping/payments/:id', to: 'shopping/payments#update'  



  ##app-specific routes 
  namespace :api do 

    namespace :v1 do 

      post "user_info" => 'token_auth#index'

    end

  end

 
end