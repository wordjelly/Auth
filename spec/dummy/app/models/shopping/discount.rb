class Shopping::Discount < Auth::Shopping::Discount
	create_es_index(INDEX_DEFINITION)
end