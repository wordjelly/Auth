Rails.application.config.middleware.use OmniAuth::Builder do

	on_failure { |env| Auth::OmniauthCallbacksController.action(:failure).call(env) }
	
	provider :facebook, FACEBOOK_CREDENTIALS[0], FACEBOOK_CREDENTIALS[1],{
	   :scope => 'email',
	   :info_fields => 'first_name,last_name,email,work',
	   :display => 'page',
	   :path_prefix => MOUNT_PATH + "/omniauth"
	}

	provider :google_oauth2, GOOGLE_CREDENTIALS[0], GOOGLE_CREDENTIALS[1],{
      :scope => "email, profile",
      :prompt => "select_account",
      :image_aspect_ratio => "square",
      :image_size => 50,
	  :path_prefix => MOUNT_PATH + "/omniauth"
  	}

end

