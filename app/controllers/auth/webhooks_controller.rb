class Auth::WebhooksController <  ApplicationController
	skip_before_action :verify_authenticity_token	
end