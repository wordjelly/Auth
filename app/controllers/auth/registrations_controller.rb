class Auth::RegistrationsController < Devise::RegistrationsController

  def create
  	puts "sign up params."
  	puts sign_up_params
    build_resource(sign_up_params)

    resource.save
    yield resource if block_given?
    if resource.persisted?
      ##(!confirmation_required? || confirmed? || confirmation_period_valid?)

      puts "resource confirmed at"
      puts resource.confirmed_at

      #puts "resource confirmed"
      #puts resource.confirmed?

      #puts "confirmation required"
      #puts !confirmation_required?

      #puts "confirmation period valid"
      #puts confirmation_period_valid?


      if resource.active_for_authentication?
        set_flash_message! :notice, :signed_up
        sign_up(resource_name, resource)
        respond_with resource, location: after_sign_up_path_for(resource)
      else
      	puts "resource not active for authentication"
        set_flash_message! :notice, :"signed_up_but_#{resource.inactive_message}"
        expire_data_after_sign_in!
        respond_with resource, location: after_inactive_sign_up_path_for(resource)
      end
    else
      clean_up_passwords resource
      set_minimum_password_length
      respond_with resource
    end
  end
	
end
