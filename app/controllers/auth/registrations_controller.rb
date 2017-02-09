class Auth::RegistrationsController < Devise::RegistrationsController
  def create
  	puts "CAME TO REGISTRATIONS CONTROLLER -> CREATE"
    build_resource(sign_up_params)

    resource.save
    yield resource if block_given?
    puts "these are the resource errors."
    puts resource.errors.full_messages
    puts "ERRORS END."
    if resource.persisted?
      puts "Resource was persisted."
      if resource.active_for_authentication?
      	puts "it is active for authentication."
        set_flash_message! :notice, :signed_up
        sign_up(resource_name, resource)
        respond_with resource, location: after_sign_up_path_for(resource)
      else
      	puts "it is not active for authentication"
        set_flash_message! :notice, :"signed_up_but_#{resource.inactive_message}"
        expire_data_after_sign_in!
        puts "after inactive sign up path is ;"
        puts after_inactive_sign_up_path_for(resource)
        respond_with resource, location: after_inactive_sign_up_path_for(resource)
      end
    else
      puts "resource was not persisted."
      clean_up_passwords resource
      set_minimum_password_length
      respond_with resource
    end
  end

end
