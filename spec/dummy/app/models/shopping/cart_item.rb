class Shopping::CartItem < Auth::Shopping::CartItem
    field :description, type: String
    field :sample_type, type: String
    field :public, type: Boolean

    ##used in cart_item_controller_concern#show
	def self.find_cart_item(params_cart_item_id,resource,pub=nil)
		return super(params_cart_item_id,resource) if pub.nil?
		all = self.where(:_id => params_cart_item_id, :public => pub)
		return all.first if all.size > 0
		return all
	end

	##used in cart_item_controller_concern#index
	def self.find_cart_items(resource,pub=nil)
		return super(resource) if pub.nil?
		self.where(:public => pub)
	end


end