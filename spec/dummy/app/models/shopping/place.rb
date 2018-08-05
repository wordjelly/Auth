class Shopping::Place < Auth::Shopping::Place
	create_es_index(INDEX_DEFINITION)
end