class Shopping::CartItemController < Auth::ApplicationController
	include Auth::Concerns::Shopping::CartItemControllerConcern
end