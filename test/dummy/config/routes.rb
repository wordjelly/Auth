Rails.application.routes.draw do
  mount Auth::Engine => "/other"
  ##we can define the controllers here if we want with a key of controllers.
  mount_omniauth_routes AUTH_RESOURCES
end
