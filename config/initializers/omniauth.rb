Rails.application.config.middleware.use OmniAuth::Builder do
	provider :facebook, FACEBOOK_CREDENTIALS[0], FACEBOOK_CREDENTIALS[1],{
	   :scope => 'email',
	   :info_fields => 'first_name,last_name,email,work',
	    :display => 'page'
	}
end