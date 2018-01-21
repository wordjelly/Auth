##need a seperate model that implements it
module Auth::Concerns::Shopping::ProductConcern

	extend ActiveSupport::Concern
	include Auth::Concerns::ChiefModelConcern
	include Auth::Concerns::OwnerConcern
	included do 
		
		#include MongoidVersionedAtomic::VAtomic	
		field :price, type: BigDecimal
		field :name, type: String

		## all products are public to be searched.
		before_save do |document|
			self.public = "yes"
		end

		if Auth.configuration.use_es == true
			include Mongoid::Elasticsearch
  			elasticsearch! ({
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
				          "shopping/product" => {
				          _all:  {
					            index_analyzer: "nGram_analyzer",
					            search_analyzer: "whitespace_analyzer"
					        },
				            properties: {
				                name: {
				                	type: "string",
				                	index: "not_analyzed"
				                },
				                price: {
				                	type: "double"
				                },
				                public: {
				                	type: "string",
				                	index: "not_analyzed",
				                	include_in_all: false
				                }
				            }
				        }
				    }
				}
			})
			
  			
			
		end

		def as_indexed_json(options={})
			 {
			 	name: name,
			    price: price
			 }
		end 
		
		
	end

	

end