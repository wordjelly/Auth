class Shopping::CartItem < Auth::Shopping::CartItem

	create_es_index(INDEX_DEFINITION)

	def set_autocomplete_tags
		self.tags = []
		self.tags << self.name 
		self.tags << self.description 
		self.tags << "item"
		if self.personality_id
			personality = Auth.configuration.personality_class.constantize.find(self.personality_id)
			personality.add_info(self.tags)
		end
	end

	def as_indexed_json(options={})
        {
            tags: self.tags,
            public: self.public,
            document_type: Auth::OmniAuth::Path.pathify(self.class.name.to_s),
            resource_id: self.resource_id,
            resource_class: self.resource_class
        }
    end
	
end