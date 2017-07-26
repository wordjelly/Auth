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
  #devise_scope :user do
  #  get "/verify_otp" => "users/confirmations#verify_otp"
  #end
  get "otp_verification_result", :action => "otp_verification_result", :controller => "otp"
  get "verify_otp", :action => "verify_otp", :controller => "otp"
  get "send_sms_otp", :action => "send_sms_otp", :controller => "otp"
  get "resend_sms_otp", :action => "resend_sms_otp", :controller => "otp"

end