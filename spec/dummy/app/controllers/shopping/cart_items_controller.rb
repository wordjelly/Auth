class Shopping::CartItemsController < Auth::Shopping::CartItemsController
	
	def index
		cart_item_params = permitted_params.fetch(:cart_item,{})
		
		if pub = cart_item_params[:public]
			@cart_items = @cart_item_class.find_cart_items({:resource => lookup_resource,:pub => pub}).page 1
		else
			super
		end
	end

	def show
		cart_item = permitted_params.fetch(:cart_item,{})
		if pub = cart_item[:public]
			options = {:cart_item_id => permitted_params[:id], :resource => lookup_resource, :pub => pub}
			@cart_item = @cart_item_class.find_cart_item(options)
		else
			super
		end
	end

	def permitted_params
		super.deep_merge(params.permit({cart_item: [:description,:sample_type,:public]}))
	end

end