class Auth::Work::CommunicationsController < Auth::Work::WorkController

	include Auth::Concerns::Work::CommunicationControllerConcern
		
	## only these actions need an authenticated user to be present for them to be executed.
    CONDITIONS_FOR_TOKEN_AUTH = [:create,:update,:destroy,:edit,:new]

    TCONDITIONS = {:only => CONDITIONS_FOR_TOKEN_AUTH}
    ##this ensures api access to this controller.
    include Auth::Concerns::DeviseConcern
    include Auth::Concerns::TokenConcern
    before_filter :do_before_request , TCONDITIONS
    before_filter :initialize_vars , TCONDITIONS
    before_filter :is_admin_user , :only => [:create,:update,:destroy,:edit]
    
    

end