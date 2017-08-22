class Shopping::TransactionsController < Auth::ApplicationController
	include Auth::Concerns::Shopping::TransactionControllerConcern
end