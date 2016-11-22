class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  before_action :configure_permitted_parameters, if: :devise_controller?

  def configure_permitted_parameters
  	#puts "came to configure permitted parameters,"
    added_attrs = [:name]
    devise_parameter_sanitizer.permit :sign_up, keys: added_attrs
    devise_parameter_sanitizer.permit :account_update, keys: added_attrs
  end

  ###NOW TESTING ALL THE PATH OVERRIDES.

  git filter-branch --force --index-filter \
'git rm --cached --ignore-unmatch ./spec/dummy/config/initializers/preinitializer.rb' \
--prune-empty --tag-name-filter cat -- --all

  
end
