class Shopping::Product < Auth::Shopping::Product
	
	create_es_index(INDEX_DEFINITION)

	
end