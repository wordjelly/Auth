module Auth::Concerns::EsConcern

	extend ActiveSupport::Concern
	
	unless Auth::Concerns::EsConcern.included_modules.include? Mongoid::Document
		include Mongoid::Document
	end

	included do 
		include Mongoid::Elasticsearch
		###########################################################
		##
		## PATCH BECAUSE ES 6.0 REMOVED MORE THAN ONE MAPPING TYPE PER INDEX, AND WE CANT HAVE SO MANY INDICES.
		##
		## the document type becomes the name of the collection singularized.
		## this is used inside the mongoid-elasticsearch gem , instead of the conventional _type, to load the results back from es.
		## the index_type is also set to this 
		## okay let me get this out of the way
		## have to pass in the index type.
		## we keep that as the same all throughout.
		###########################################################
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

		## masked tags
		field :masked_tags, type: Array, default: []

		## OPTIONAL
		## an optional description that will be shown below the result in the autocomplete.
		field :autocomplete_description, type: String 

		AUTOCOMPLETE_INDEX_SETTINGS ||=
			{
				number_of_shards: 1,
				number_of_replicas: 0,
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

		AUTOCOMPLETE_INDEX_MAPPINGS ||= 
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
                },
                document_type: {
                	type: "keyword"
                }
            }
        }

        ###########################################################
        ##
        ##
        ## CONSTANTS FOR SECONDARY LINKS, TO BE USED IN THE IMPLEMENTING MODELS.
        ##
        ##
        ###########################################################

        NEW ||= "Add New"
        EDIT ||= "Edit"
        SEE_ALL ||= "See All"
        SEE_RELATED ||= "See Related"

        ###########################################################
        ##
        ## the primary link, masked tags and tags must all three be prsent, before the document can be saved.
        ##
        ###########################################################
        validates_presence_of :primary_link
        validates_presence_of :tags

        before_validation do |document|
        	document.set_primary_link
        	document.set_secondary_links
        	document.set_autocomplete_description
        	document.set_autocomplete_tags
        	document.add_created_at
        	document.add_attributes_for_tags
        end

        ## unless the document is embedded, it will be added to the index after saved
        ## if the document is embedded, it can only be added to the es_index, through the controller create/update actions.
        after_save do |document|
			unless document.class.embedded?
				document.es_update
			end
		end
    
		field :public, type:String, default: "no"

		field :document_type, type:String

		def es_concern_attributes
			["tags","autocomplete_description"]
		end

		## the tags field should be cleared and reassmebled
		## its that simple.

		def attributes_for_tags
			[]
		end

		## this is all that is needed to add these tags.
		def add_attributes_for_tags
			self.attributes_for_tags.each do |k|
				self.tags << self.send("#{k}").to_s
			end
		end


		## so lets see if this even works.
		def self.create_es_index(definition)
			## check the presence of a resource_id and a resource_class
			#raise "Please define a resource_id field on this model to use it with elasticsearch, this field should be a string" unless self.respond_to? :resource_id
			#raise "Please define a resource_class field on this model as well." unless self.respond_to? :resource_class
			definition ||= {}
			## so we are going to overwrite the document here
			## and we are adding a document_type.
			## 
			#definition.merge!({:index_type => "pathofast_document"})
			## now let me create only one index
			## the problem is that does it somehow help to know what should be the type
			## will have to modify the gem to set the default type as document or something
			## then we can add the document type internally.
			if Auth.configuration.use_es == true
				elasticsearch! (
						definition
					)
			end
		
		end	

=begin 
		def as_indexed_json(options={})
			{
				tags: self.tags,
				public: self.public,
				document_type: Auth::OmniAuth::Path.pathify(self.class.name.to_s),
				resource_id: self.resource_id,
				resource_class: self.resource_class
			}
		end
=end	
	end



	def set_autocomplete_tags

	end

	def set_primary_link

	end

	def set_secondary_links

	end

	def set_autocomplete_description

	end

=begin
	def created_at=(created_at)
			
		
		super(created_at)
		
		return unless self.created_at
		
		human_readable = self.created_at.strftime("%B %-d %Y")
		self.tags << human_readable unless self.tags.include? human_readable

		
		self.masked_tags << human_readable unless self.tags.include? human_readable
		
	end
=end

	def add_created_at
		human_readable = self.created_at.strftime("%B %-d %Y") if self.created_at
		self.tags << human_readable unless self.tags.include? human_readable
	end

	def clear_autocomplete_data
		self.primary_link = nil
		self.secondary_links.clear
		self.autocomplete_description = nil
		self.masked_tags.clear
		self.tags.clear
	end

	

end