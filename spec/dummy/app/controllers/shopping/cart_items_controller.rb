class Shopping::CartItemsController < Auth::Shopping::CartItemsController
	

	def public_cart_items
		@cart_items = Shopping::CartItems.where(:public => true).page 1
	end


	def permitted_params
		super.deep_merge(params.permit({cart_item: [:description,:sample_type,:public]}))
	end

end