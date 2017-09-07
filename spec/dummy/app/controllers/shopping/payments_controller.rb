class Shopping::PaymentsController < Auth::Shopping::PaymentsController
	
	include Auth::Concerns::Shopping::PayUMoneyControllerConcern
	
end