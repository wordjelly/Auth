class Auth::Shopping::CartItemsController < Auth::Shopping::ShoppingController
	include Auth::Concerns::Shopping::CartItemControllerConcern
    TCONDITIONS = {:only => Auth.configuration.cart_item_controller_token_auth_actions}
    include Auth::Concerns::DeviseConcern
    include Auth::Concerns::TokenConcern
    before_action :do_before_request , TCONDITIONS
    before_action :initialize_vars , TCONDITIONS
end