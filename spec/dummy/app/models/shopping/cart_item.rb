class Shopping::CartItem < Auth::Shopping::CartItem
    field :description, type: String
    field :sample_type, type: String
    field :public, type: Boolean

    ##used in cart_item_controller_concern#show
    ##params_cart_item_id,resource,pub=nil
	def self.find_cart_item(options)
		return super(options) if options[:pub].nil?
		all = self.where(:_id => options[:cart_item_id], :public => options[:pub])
		return all.first if all.size > 0
		return all
	end

	##used in cart_item_controller_concern#index
	##resource,pub
	def self.find_cart_items(options)
		return super(options) if options[:pub].nil?
		self.where(:public => options[:pub])
	end


end