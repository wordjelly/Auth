class Auth::Shopping::CartsController < Auth::Shopping::ShoppingController
	include Auth::Concerns::Shopping::CartControllerConcern
	include Auth::Concerns::DeviseConcern
    include Auth::Concerns::TokenConcern

    before_filter :do_before_request  , :only => [:create,:update,:destroy,:show,:index, :new]
    before_filter :initialize_vars, :only => [:create,:update,:destroy,:show,:index, :new]
end
