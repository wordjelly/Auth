class Shopping::CartItemsController < Auth::ApplicationController
	include Auth::Concerns::Shopping::CartItemControllerConcern
end