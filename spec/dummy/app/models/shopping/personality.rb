class Shopping::Personality < Auth::Shopping::Personality
	create_es_index(INDEX_DEFINITION)
end