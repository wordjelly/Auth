##need a seperate model that implements it
module Auth::Concerns::Shopping::ProductConcern

	extend ActiveSupport::Concern
	include Auth::Concerns::ChiefModelConcern
	include Auth::Concerns::OwnerConcern
	include Auth::Concerns::EsConcern
	


	included do 
	
		#embeds_many :specifications, :class_name => Auth.configuration.specification_class

		embeds_many :cycles, :class_name => "Auth::Work::Cycle", :as => :product_cycles

					
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
					                },
					                bundle_name: {
					                	type: "text",
					                	copy_to: "_all_fields",
					                	fields: {
					                		raw: {
					                			type: "keyword"
					                		}
					                	}    		
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

		field :description, type: String, default: "Available"

		field :badge_text, type: String, default: "Delivery in 30 mins"

		field :badge_class, type: String, default: "new badge"

		## so i create a bundle and add 5 products to it,
		## and then modify their prices ?
		## what about all the notifications and everythign ?
		## will have to replicate all that ?
		## 
		field :bundle_name, type: String

		## all products are public to be searched.
		before_save do |document|
			self.public = "yes"
		end

		## forget it.

	end

	


	def as_indexed_json(options={})
	 {
	 	name: name,
	 	bundle_name: bundle_name,
	    price: price,
	    resource_id: resource_id,
	    public: public
	 }
	end 


	module ClassMethods

		## @return[SearchResult]
		def bundle_autocomplete_aggregation(query)
			query[:body][:aggregations] = {
				bundle_names: {
					terms: {
						field: "bundle_name.raw"
					}
				}
			}
			
			result = Auth.configuration.product_class.constantize.es.search query

			puts "these are the aggs."
			puts result.raw_response.to_s
			#mash = Hashie::Mash.new result		
			#has_more_results = false if mash.aggregations.bundle_names["buckets"].size == 0
			#mash.aggregations.bundle_names["buckets"].each do |bucket|
			#		puts "this is the bucket: "
			#		puts bucket.to_s
					#after = bucket["key"]["symptom_thing"]
					#doc_count = bucket["doc_count"]
					#create_symptom(after,doc_count)
					#puts "created #{counter} symptoms"
					#counter+=1
			#end
=begin
			mash = Hashie::Mash.new symptom_co_occurrence_query
				has_more_results = false if mash.aggregations.my_buckets["buckets"].size == 0
				mash.aggregations.my_buckets["buckets"].each do |bucket|
					after = bucket["key"]["symptom_thing"]
					doc_count = bucket["doc_count"]
					create_symptom(after,doc_count)
					puts "created #{counter} symptoms"
					counter+=1
				end
=end
		end

		## so we have completed the rolling n minutes.
		def add_to_previous_rolling_n_minutes(minutes,origin_epoch,cycle_to_add)

			## get all the minutes less than that.
			rolling_n_minutes_less_than_that = minutes.keys.select{|c| c < origin_epoch}			

			end_min = rolling_n_minutes_less_than_that.size < Auth.configuration.rolling_minutes ? rolling_n_minutes_less_than_that.size : Auth.configuration.rolling_minutes

			end_min = end_min - 1

			end_min = end_min > 0 ? end_min : 0
			rolling_n_minutes_less_than_that[0..end_min].each do |epoch|
				minutes[epoch].cycles << cycle_to_add
			end

		end

		## adds the relevant cycles to the minutes, and returns the hash that came in.
		## does not save the minutes, after adding the cycles to them.
		##@return[Hash] {epoch => minute object}
		def schedule_cycles(minutes,location_id,conditions = {})

			products = Auth.configuration.product_class.constantize.all if conditions.blank?

			products = Auth.configuration.product_class.constantize.where(conditions) if !conditions.blank?

			minutes.keys.each do |epoch|
				
				products.each do |product|
				
					all_cycles_valid = true
					product.cycles.each do |cycle|

						all_cycles_valid = cycle.requirements_satisfied(epoch + cycle.time_since_prev_cycle.minutes*60,location_id)
								
					end


					if all_cycles_valid == true
						cycle_chain = []
						product.cycles.each do |cycle|
							epoch_at_which_to_add = epoch + cycle.time_since_prev_cycle.minutes*60
							cycle_to_add = cycle.dup
							cycle_to_add.start_time = epoch_at_which_to_add
							cycle_to_add.end_time = cycle_to_add.start_time + cycle_to_add.duration
							cycle_to_add.cycle_chain = cycle_chain
							if minutes[epoch_at_which_to_add]
								
								#add_to_previous_rolling_n_minutes(minutes,epoch_at_which_to_add,cycle_to_add)


								minutes[epoch_at_which_to_add].cycles << cycle_to_add



								cycle_chain << cycle_to_add.id.to_s
							else
								#raise "necessary minute not in range."
							end
						end
					end
				end
			end
			minutes
		end
	end
end
