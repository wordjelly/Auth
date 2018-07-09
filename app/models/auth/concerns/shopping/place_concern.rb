module Auth::Concerns::Shopping::PlaceConcern

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
			          Auth::OmniAuth::Path.pathify(Auth.configuration.place_class) => {
			            properties: {
			            	_all_fields:  {
			            		type: "text",
				            	analyzer: "nGram_analyzer",
				            	search_analyzer: "whitespace_analyzer"
				        	},
			                nearest_address: {
			                	type: "keyword",
			                	copy_to: "_all_fields"
			                },
			                unit_number: {
			                	type: "keyword",
			                	copy_to: "_all_fields"
			                },
			                building: {
			                	type: "keyword",
			                	copy_to: "_all_fields"
			                },
			                street: {
			                	type: "keyword",
			                	copy_to: "_all_fields"
			                },
			                city: {
			                	type: "keyword",
			                	copy_to: "_all_fields"
			                },
			                country_state: {
			                	type: "keyword",
			                	copy_to: "_all_fields"
			                },
			                country: {
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

		field :nearest_address, type: String

		field :latitude, type: String

		field :longitude, type: String

		field :unit_number, type: String

		field :building, type: String

		field :street, type: String

		field :pin_code, type: Integer
		
		field :city, type: String
		
		field :country_state, type: String
		
		field :country, type: String

	end

	def get_address_from_details
		address = ""
		[:unit_number,:building,:street,:city,:country_state,:country,:pin_code].each do |component|
			address += (" " + self.send(component).to_s) unless self.send(component).nil?
		end
		address
	end

	module ClassMethods
		def find_places(options)
			conditions = {:resource_id => nil, :parent_id => nil}
			conditions[:resource_id] = options[:resource].id.to_s if options[:resource]
			Auth.configuration.place_class.constantize.where(conditions)
		end
	end
end

##
