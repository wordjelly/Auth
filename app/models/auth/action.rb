class Action

	include Auth::Concerns::EsConcern
	
	INDEX_DEFINITION = {
		index_name: Auth.configuration.brand_name.downcase,
		index_options:  {
		        settings:  {
		    		index: Auth::Concerns::EsConcern::AUTOCOMPLETE_INDEX_SETTINGS
			    },
		        mappings: {
		          "document" => Auth::Concerns::EsConcern::AUTOCOMPLETE_INDEX_MAPPINGS
		    }
		}
	}

	
	field :action_name, type: String
	
	field :action_link, type: String
	
	field :action_description, type: String

	## we need to set the tags and primary and secondary links.
	## and also call set_es.
	## does not reliably delete users from elasticsearch.
	## how are they going to search without a name.

end