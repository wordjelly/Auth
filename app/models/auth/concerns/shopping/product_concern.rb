##need a seperate model that implements it
module Auth::Concerns::Shopping::ProductConcern

	extend ActiveSupport::Concern
	include Auth::Concerns::ChiefModelConcern
	include Auth::Concerns::OwnerConcern
	include Auth::Concerns::EsConcern
	

	included do 
	
	embeds_many :specifications, :class_name => Auth.configuration.specification_class

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
				          Auth::OmniAuth::Path.pathify(Auth.configuration.product_class) => {
				            properties: {
				            	_all_fields: {
				            		type: "text",
				            		analyzer: "nGram_analyzer",
					            	search_analyzer: "whitespace_analyzer"
				            	},
				                name: {
				                	type: "keyword",
				                	copy_to: "_all_fields"
				                },
				                price: {
				                	type: "double",
				                	copy_to: "_all_fields"
				                },
				                public: {
				                	type: "keyword"
				                },
				                resource_id: {
				                	type: "keyword",
				                	copy_to: "_all_fields"
				                }
				            }
				        }
				    }
				}
			}
		#include MongoidVersionedAtomic::VAtomic	
		field :price, type: BigDecimal
		field :name, type: String
		field :stock, type: Float, default: 0.0

		## for WORKFLOW
		#field :location_information, type: Hash, default: {}
		#field :time_information, type: Hash, default: {}
		
				


		## all products are public to be searched.
		before_save do |document|
			self.public = "yes"
		end

		

	end

	def as_indexed_json(options={})
	 {
	 	name: name,
	    price: price,
	    resource_id: resource_id,
	    public: public
	 }
	end 


	def get_specification(address)
		self.specifications.select{|c| c.address == address}.first
	end


end