class Shopping::CartItemsController < Auth::Shopping::CartItemsController
	
	def index
		cart_item_params = permitted_params.fetch(:cart_item,{})
		if pub = cart_item_params[:public]
			@cart_items = @cart_item_class.find_cart_items(lookup_resource,pub).page 1
		else
			super
		end
	end

	def show
		cart_item = permitted_params.fetch(:cart_item,{})
		if pub = cart_item[:public]
			@cart_item = @cart_item_class.find_cart_item(permitted_params[:id],lookup_resource,pub)
		else
			super
		end
	end

	def permitted_params
		super.deep_merge(params.permit({cart_item: [:description,:sample_type,:public]}))
	end

end