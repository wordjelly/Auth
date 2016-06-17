Rails.application.routes.draw do
  mount Auth::Engine => "/other"
  ##we can define the controllers here if we want with a key of controllers.
  mount_devise_token_auth_for 'User', {}
end
