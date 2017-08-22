class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception
  layout 'auth/application'  
 
  respond_to :html,:js,:json
  #include User::ParameterSanitizer
  #before_action :configure_permitted_parameters, if: :devise_controller?

  #def configure_permitted_parameters
  	#puts "came to configure permitted parameters,"
    #added_attrs = [:name]
    #devise_parameter_sanitizer.permit :sign_up, keys: added_attrs
    #devise_parameter_sanitizer.permit :account_update, keys: added_attrs
  #end

  ###NOW TESTING ALL THE PATH OVERRIDES.
  ###THESE ARE OVERRIDDEN FOR ADMIN ONLY.
  ##i also have to test the path helpers.
  def after_sign_in_path_for(resource)
    if resource.class.name.to_s == "Admin"
      ##we wanna set a different path, and test that it goes there in the specs.
      new_topic_path
    else
      super
    end
  end

  def after_sign_out_path_for(resource)
    super
  end

  def after_sign_up_path_for(resource)
    super
  end

  def after_inactive_sign_up_path_for(resource)
    super
  end

  protected

  def devise_parameter_sanitizer
    if resource_class == User
      User::ParameterSanitizer.new(User, :user, params)
    elsif resource_class == Admin
      Admin::ParameterSanitizer.new(Admin,:admin,params)
    else
      super # Use the default one
    end
  end

end
