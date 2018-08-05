class Shopping::CartItem < Auth::Shopping::CartItem

	create_es_index(INDEX_DEFINITION)

	def set_autocomplete_tags
		if self.new_record?
			self.tags << self.name 
			self.tags << self.description 
			self.tags << "item"
			if self.personality_id
				personality = Auth.configuration.personality_class.constantize.find(self.personality_id)
				personality.add_info(self.tags)
			end
		end
	end
	
end