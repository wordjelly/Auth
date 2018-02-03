class Auth::Shopping::CartItemsController < Auth::Shopping::ShoppingController
	include Auth::Concerns::Shopping::CartItemControllerConcern

		
	## only these actions need an authenticated user to be present for them to be executed.
    CONDITIONS_FOR_TOKEN_AUTH = [:create,:update,:destroy,:edit,:new,:index,:show,:create_multiple]

    TCONDITIONS = {:only => CONDITIONS_FOR_TOKEN_AUTH}
    ##this ensures api access to this controller.
    include Auth::Concerns::DeviseConcern
    include Auth::Concerns::TokenConcern
    before_filter :do_before_request , TCONDITIONS
    before_filter :initialize_vars , TCONDITIONS
end