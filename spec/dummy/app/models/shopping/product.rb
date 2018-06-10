class Shopping::Product < Auth::Shopping::Product
	
	create_es_index(INDEX_DEFINITION)

	def as_indexed_json(options={})
    
         {
            name: name,
            price: price,
            resource_id: resource_id,
            public: public
         }
 	end

end