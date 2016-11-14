class Auth::ConfirmationsController <  Devise::ConfirmationsController
  def create
  	puts "Came to create request."
    self.resource = resource_class.send_confirmation_instructions(resource_params)
    yield resource if block_given?
    puts resource.errors.full_messages.to_s
    if successfully_sent?(resource)
      puts "was successfully sent."
      respond_with({}, location: after_resending_confirmation_instructions_path_for(resource_name))
    else
      respond_with(resource)
    end
  end  
end
