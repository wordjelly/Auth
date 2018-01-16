class Auth::Shopping::ProductsController < Auth::Shopping::ShoppingController


	include Auth::Concerns::Shopping::ProductControllerConcern
		
	## only these actions need an authenticated user to be present for them to be executed.
    CONDITIONS_FOR_TOKEN_AUTH = [:create,:update,:destroy]

    TCONDITIONS = {:only => CONDITIONS_FOR_TOKEN_AUTH}
    ##this ensures api access to this controller.
    include Auth::Concerns::DeviseConcern
    include Auth::Concerns::TokenConcern
    before_filter :do_before_request , TCONDITIONS
    before_filter :initialize_vars , TCONDITIONS
    before_filter :is_admin_user , :only => [:create,:update,:destroy]
	
end