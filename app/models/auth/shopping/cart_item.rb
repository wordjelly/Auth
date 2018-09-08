class Auth::Shopping::CartItem
	include Auth::Concerns::Shopping::CartItemConcern
	def attributes_for_tags
		["name","description"]
	end
end