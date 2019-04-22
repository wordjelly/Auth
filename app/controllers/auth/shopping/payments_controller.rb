class Auth::Shopping::PaymentsController < Auth::Shopping::ShoppingController
	include Auth::Concerns::Shopping::PaymentControllerConcern
		
	## only these actions need an authenticated user to be present for them to be executed.
    CONDITIONS_FOR_TOKEN_AUTH = [:create,:update,:destroy,:edit,:new,:index,:show]

    TCONDITIONS = {:only => CONDITIONS_FOR_TOKEN_AUTH}
    ##this ensures api access to this controller.
    include Auth::Concerns::DeviseConcern
    include Auth::Concerns::TokenConcern
    before_action :do_before_request , TCONDITIONS
    before_action :initialize_vars , TCONDITIONS
end