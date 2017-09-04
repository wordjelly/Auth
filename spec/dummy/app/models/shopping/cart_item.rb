class Shopping::CartItem < Auth::Shopping::CartItem
    field :description, type: String
    field :sample_type, type: String
    field :public, type: Boolean

    ##used in cart_item_controller_concern#show
	def self.find_cart_item(params_cart_item_id,resource)
		conditions = {:_id => params_cart_item_id}
		if resource.nil?
			conditions[:public] = true
		else
			conditions[:resource_id] = resource.id.to_s
		end
		self.where(conditions).first
	end

	##used in cart_item_controller_concern#index
	def self.find_cart_items(resource)
		conditions = {}
		if resource.nil?
			conditions[:public] = true
		else
			conditions[:resource] = resource.id.to_s
		end
		self.where(conditions)
	end


end