class Auth::Shopping::Place
	include Auth::Concerns::Shopping::PlaceConcern
	def attributes_for_tags
		["unit_number","building","street","pin_code","city","country_state","country"]
	end
end