class Shopping::Product < Auth::Shopping::Product
	
	include Auth::Concerns::Work::GoodConcern

	create_es_index(INDEX_DEFINITION)

   def set_autocomplete_tags
      if self.new_record?
         self.tags << "product"
         self.tags << self.name
         self.tags << self.description
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