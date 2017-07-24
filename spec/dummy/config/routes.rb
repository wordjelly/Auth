Rails.application.routes.draw do

  resources :topics
  
  
  get 'get_activities' , :action => "get_activities", :controller => "activity"


  root "home#index"
  #mount Auth::Engine => "/authenticate", :as => 'auth'
  mount_routes Auth.configuration.auth_resources
  
  ##app-specific routes 
  namespace :api do 

    namespace :v1 do 

      post "user_info" => 'token_auth#index'

    end

  end

  ##need to add the routes for sms otp in case you are using the 
  ##sms_otp_concern in the confirmations_controller, and the model.
  get "verify_otp", :action => "verify_otp", :controller => "users/confirmations"
  get "send_sms_otp", :action => "send_sms_otp", :controller => "users/confirmations"
  get "request_otp_input", :action => "request_otp_input", :controller => "users/confirmations"

end