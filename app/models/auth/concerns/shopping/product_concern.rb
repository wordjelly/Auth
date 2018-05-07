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
		## a product can only belong to one bunch.
		field :bunch, type: String
		##PERMITTED
		##the number of this product that are being added to the cart
		##permitted
		field :quantity, type: Float, default: 1
		## for WORKFLOW
		#field :location_information, type: Hash, default: {}
		#field :time_information, type: Hash, default: {}
		field :miscellaneous_attributes, type: Hash, default: {}

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



	##################################################################
	##
	##
	## FOR SYSTEM.
	##
	##
	##################################################################

	def get_group_value(group_by_key)
		if group_by_key == "*" 
			return "*"
		else
			return self.miscellaneous_attributes[group_by_key]
		end
	end
	
	## @param[String] req : the requirement from the definition. It consists of "*" wildcard, or a product id, or a definition address + product_id -> which is basically one of the output products of the definition.
	## @return[Boolean] : true/false if this product satisfies the requirement or not.
	def satisfies_requirement(req)
		if ((req == self.id.to_s) || (req == "*"))
			true
		elsif req == (self.miscellaneous_attributes[:address] + ":" + self.id.to_s)
			true
		else
			false
		end
	end

end