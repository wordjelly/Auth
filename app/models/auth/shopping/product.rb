class Auth::Shopping::Product
	include Auth::Concerns::Shopping::ProductConcern
	def attributes_for_tags
		["name","description"]
	end
end