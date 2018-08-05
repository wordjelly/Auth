class Shopping::Cart < Auth::Shopping::Cart
	create_es_index(INDEX_DEFINITION)
end