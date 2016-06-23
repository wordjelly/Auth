Rails.application.routes.draw do
  mount Auth::Engine => Auth.configuration.mount_path
  mount_routes Auth.configuration.auth_resources
end
