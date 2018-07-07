module Auth::Concerns::Shopping::PersonalityConcern

	extend ActiveSupport::Concern
	include Auth::Concerns::OwnerConcern
	include Auth::Concerns::EsConcern	

	included do 

		INDEX_DEFINITION = {
			index_options:  {
			        settings:  {
			    		index: {
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
				    },
			        mappings: {
			          Auth::OmniAuth::Path.pathify(Auth.configuration.personality_class) => {
			            properties: {
			            	_all_fields:  {
			            		type: "text",
				            	analyzer: "nGram_analyzer",
				            	search_analyzer: "whitespace_analyzer"
				        	},
			                fullname: {
			                	type: "keyword",
			                	copy_to: "_all_fields"
			                }
			            }
			        }
			    }
			}
		}
	
		before_save do |document|
			document.public = "no"
		end

		## this will get stored as an epoch.
		field :date_of_birth, type: Integer
		
		## full name
		field :fullname, type: String


		field :sex, type: String
	end

	## @param[Hash] options : can contain a :resource key. which should be the resource(user) to which all the personalities belong.
	module ClassMethods
		def find_personalities(options)
			conditions = {:resource_id => nil, :parent_id => nil}
			conditions[:resource_id] = options[:resource].id.to_s if options[:resource]
			puts "conditions are:"
			puts conditions.to_s
			Auth.configuration.personality_class.constantize.where(conditions)
		end
	end
end