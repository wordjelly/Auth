class Auth::Shopping::PaymentsController < Auth::Shopping::ShoppingController
	include Auth::Concerns::Shopping::PaymentControllerConcern
	include Auth::Concerns::DeviseConcern
    include Auth::Concerns::TokenConcern

    before_filter :do_before_request  , :only => [:create,:update,:destroy,:show,:index, :new]
    before_filter :initialize_vars, :only => [:create,:update,:destroy,:show,:index, :new]
end