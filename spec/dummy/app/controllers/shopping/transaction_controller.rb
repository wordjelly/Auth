class Shopping::TransactionController < Auth::ApplicationController
	include Auth::Concerns::Shopping::TransactionControllerConcern
end