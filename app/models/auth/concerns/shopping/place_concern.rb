module Auth::Concerns::Shopping::PlaceConcern

	extend ActiveSupport::Concern
	include Auth::Concerns::OwnerConcern
	include Auth::Concerns::EsConcern	


	included do 

=begin
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
=end		
		
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


	#################################################################
	##
	##
	## AUTOCOMPLETE METHODS.
	##
	##
	#################################################################

	def set_primary_link
		self.primary_link = Rails.application.routes.url_helpers.send(Auth::OmniAuth::Path.show_or_update_or_delete_path(Auth.configuration.place_class),self.id.to_s)
	end	

	def set_secondary_links 
		unless self.secondary_links["See All Carts"]
			
		end

		unless self.secondary_links["See Latest Cart"]

		end

		unless self.secondary_links["See Pending Carts"]

		end

		unless self.secondary_links["Edit Information"]
		
		end
	end

	def set_autocomplete_tags
		self.tags = []
		self.tags << "Place"
	end

	def set_autocomplete_description
		
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
