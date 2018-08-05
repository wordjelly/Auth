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

end