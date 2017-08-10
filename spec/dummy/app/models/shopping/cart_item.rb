class Shopping::CartItem
	include Mongoid::Document
	include Mongoid::Timestamps
	include Auth::Concerns::Shopping::CartItemConcern
end