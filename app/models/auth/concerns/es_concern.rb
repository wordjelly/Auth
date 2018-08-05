module Auth::Concerns::EsConcern

	extend ActiveSupport::Concern
	
	unless Auth::Concerns::EsConcern.included_modules.include? Mongoid::Document
		include Mongoid::Document
	end

	included do 

		## the page to which the user will be taken if they click on the suggestion.
		## REQUIRED
		field :primary_link, type: String


		## key -> display name
		## value -> hash
		## value_key -> :url -> the url
		## value_key -> :data -> hash of optional data-attributes.
		field :secondary_links, type: Hash, default: {}


		## now let us configure that bitch to show this bitch.
		## REQUIRED
		## array of tags on which to do the autocomplete
		field :tags, type: Array, default: []

		## OPTIONAL
		## an optional description that will be shown below the result in the autocomplete.
		field :autocomplete_description, type: String 

		AUTOCOMPLETE_INDEX_SETTINGS =
			{
		        analysis:  {
		            filter:  {
		                nGram_filter:  {
		                    type: "nGram",
		                    min_gram: 2,
		                    max_gram: 20,
		                   	token_chars: [
		                       "letter",
		                       "digit",
		                       "punctuation",
		                       "symbol"
		                    ]
		                }
		            },
		            analyzer:  {
		                nGram_analyzer:  {
		                    type: "custom",
		                    tokenizer:  "whitespace",
		                    filter: [
		                        "lowercase",
		                        "asciifolding",
		                        "nGram_filter"
		                    ]
		                },
		                whitespace_analyzer: {
		                    type: "custom",
		                    tokenizer: "whitespace",
		                    filter: [
		                        "lowercase",
		                        "asciifolding"
		                    ]
		                }
		            }
		        }
			}

		AUTOCOMPLETE_INDEX_MAPPINGS = 
		{
            properties: {
            	tags:  {
            		type: "text",
	            	analyzer: "nGram_analyzer",
	            	search_analyzer: "whitespace_analyzer"
	        	},
                public: {
                	type: "keyword"
                },
                resource_id: {
                	type: "keyword"
                }
            }
        }

        before_save do |document|
        	document.set_primary_link
        	document.set_secondary_links
        	document.set_autocomplete_description
        	document.set_autocomplete_tags
        end



		field :public, type:String, default: "no"


		def self.create_es_index(definition)
			## check the presence of a resource_id and a resource_class
			#raise "Please define a resource_id field on this model to use it with elasticsearch, this field should be a string" unless self.respond_to? :resource_id
			#raise "Please define a resource_class field on this model as well." unless self.respond_to? :resource_class
			definition ||= {}
			if Auth.configuration.use_es == true
				include Mongoid::Elasticsearch
				elasticsearch! (
						definition
					)
			end
		
		end	

	end

	def as_indexed_json(options={})
		{
			tags: self.tags,
			public: self.public,
			resource_id: self.resource_id,
			resource_class: self.resource_class
		}
	end


	def set_autocomplete_tags

	end

	def set_primary_link

	end

	def set_secondary_links

	end

	def set_autocomplete_description

	end

	def created_at=(created_at)
		
		super(created_at)
		
		return unless self.created_at
		
		human_readable = self.created_at.strftime("%B %-d %Y")
		self.tags << human_readable unless self.tags.include? human_readable		
	end

	def clear_autocomplete_data
		self.primary_link = nil
		self.secondary_links.clear
		self.autocomplete_description = nil
		self.tags.clear
	end

end