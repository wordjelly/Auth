class Auth::Shopping::CartsController < Auth::Shopping::ShoppingController
	include Auth::Concerns::Shopping::CartControllerConcern
    TCONDITIONS = {:only => Auth.configuration.cart_controller_token_auth_actions}
    ##this ensures api access to this controller.
    include Auth::Concerns::DeviseConcern
    include Auth::Concerns::TokenConcern
    before_filter :do_before_request , TCONDITIONS
    before_filter :initialize_vars , TCONDITIONS
end
