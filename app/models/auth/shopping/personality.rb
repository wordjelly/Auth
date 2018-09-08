class Auth::Shopping::Personality
	
	include Auth::Concerns::Shopping::PersonalityConcern

	FIXED_FIELD_OPTIONS = {
		:sex => ["Male","Female"]
	}

	def attributes_for_tags
		["fullname","sex","age"]
	end

end