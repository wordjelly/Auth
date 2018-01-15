class Auth::Shopping::PaymentsController < Auth::Shopping::ShoppingController
	include Auth::Concerns::Shopping::PaymentControllerConcern
end