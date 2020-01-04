##need a seperate model that implements it
module Auth::Concerns::Shopping::ProductConcern

	extend ActiveSupport::Concern
	include Auth::Concerns::ChiefModelConcern
	include Auth::Concerns::OwnerConcern
	include Auth::Concerns::EsConcern
	include Mongoid::Autoinc	

	if Auth.configuration.enable_barcode_api == true
		include Auth::Concerns::Shopping::BarCodeConcern
	end

	included do 
		
		embeds_many :cycles, :class_name => "Auth::Work::Cycle", :as => :product_cycles

		embeds_many :instructions, :class_name => "Auth::Work::Instruction", :as => :product_instructions
		
		INDEX_DEFINITION ||= 
		{
			index_name: Auth.configuration.brand_name.downcase,
			index_options:  
				{
				settings:  
					{
				    		index: Auth::Concerns::EsConcern::AUTOCOMPLETE_INDEX_SETTINGS
					},
				mappings: 
					{
				        "document" => Auth::Concerns::EsConcern::AUTOCOMPLETE_INDEX_MAPPINGS.deep_merge(
				        		{
				        			properties: {
				        				bundle_name: {
				        					type: "text",
				        					fields: {
				        						raw: {
				        							type: "keyword"
				        						}
				        					}
				        				}
				        			}
				        		}
				        	)
				    }
				}
		}

		#include MongoidVersionedAtomic::VAtomic	
		field :price, type: Float
		field :name, type: String
		## a product can only belong to one bunch.
		field :bunch, type: String
	
		field :quantity, type: Float, default: 1
		## for WORKFLOW
		#field :location_information, type: Hash, default: {}
		#field :time_information, type: Hash, default: {}
		field :miscellaneous_attributes, type: Hash, default: {}

		field :description, type: String, default: "Available"

		field :badge_text, type: String, default: "Delivery in 30 mins"

		field :badge_class, type: String, default: "new badge"

		## so we have a bundle name,
		## this has already been done.
		## we have to make this bundle name barcode scannable.
		## or autoassignable.
		field :bundle_name, type: String

			
		before_save do |document|
			self.public = "yes"
		end

		after_initialize do |document|

			if ((document.new_record?) && (document.create_from_product_id))
				
				begin
					create_from_product = Auth.configuration.product_class.constantize.find(self.create_from_product_id)
					unless create_from_product.product_code.blank?
						
						document.attrs_to_copy_from_prod_to_prod.each do |attr|
							document.send("#{attr}=",create_from_product.send("#{attr}"))
						end
					end
				rescue Mongoid::Errors::DocumentNotFound => e
					puts e.to_s
				end
			end
		end

		###########################################################
		##
		##
		## THE WHOLE MATTER OF PRODUCT TYPE CODES.
		##
		##
		###########################################################

		## this is automatically assigned to whatever is the calculated hashid, only if it is not already set, so that is is done, in the write attribute hook.
		field :product_code, type: String

		field :auto_incrementing_number, type: Integer

		increments :auto_incrementing_number

		field :unique_hash_id, type: String

		## first lets do the specs

		attr_accessor :create_from_product_id
		
		############################################################

	end

	def write_attribute(field,value)
		super(field,value)
		if field.to_s == "auto_incrementing_number"
			if self.auto_incrementing_number_changed?
				unless self.unique_hash_id
					hashids = Hashids.new(Auth.configuration.hashids_salt,0,Auth.configuration.hashids_alphabet)
					self.unique_hash_id = hashids.encode(self.auto_incrementing_number)
					## check if the option that create from product id is ticked, then assign that otherwise give it its own new product code
					if self.create_from_product_id
						
					else
						self.product_code = self.unique_hash_id if (self.product_code.blank?)
					end
				end
			end
		end
	end


	def attrs_to_copy_from_prod_to_prod
		["product_code","name","description","price"]
	end


=begin
	def as_indexed_json(options={})
	 puts "super is:"
	 puts super
	 super.merge({bundle_name: bundle_name})
	end 
=end	

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

	## here need to add this action links to the products.
	## it is basically a form to add a cart item
	## that should be added hereitself.
	## 
	def set_secondary_links
		## this can be done both as a user and as an admin.
		## what if the admin assigns it for himself.
		## these checks have to be established for everyone.
		unless self.secondary_links["Order Now"]
			self.secondary_links["Order Now"] = {
				:partial => "auth/shopping/products/show/action_links.html.erb",
				:instance_name_in_locals => "product", 
				:other_locals => {}
			}
		end

		unless self.secondary_links["Edit Product"]
			self.secondary_links["Edit Product"] = {
				:url => Rails.application.routes.url_helpers.send(Auth::OmniAuth::Path.edit_path(Auth.configuration.product_class),self.id.to_s)
			}
		end

		unless self.secondary_links["See All Products"]
			## for this the url is ===> index path.
			self.secondary_links["See All Products"] = {
				:url => Rails.application.routes.url_helpers.send(Auth::OmniAuth::Path.create_or_index_path(Auth.configuration.product_class),{})
			}

		end

		unless self.secondary_links["See Related Products"]
			self.secondary_links["See All Products"] = {
				:url => Rails.application.routes.url_helpers.send(Auth::OmniAuth::Path.create_or_index_path(Auth.configuration.product_class),{})
			}

		end
		
		unless self.secondary_links["Add New Product"]
			self.secondary_links["Add New Product"] = {
				:partial => "auth/shopping/products/search_results/add_product.html.erb",
				:instance_name_in_locals => "product", 
				:other_locals => {}	
			}
		end

	end

	
	def set_autocomplete_tags
		self.tags = []
		self.tags << "product"
	end

	def set_autocomplete_description
		self.autocomplete_description = self.name + " - " + self.description
	end

	def set_primary_link
		self.primary_link = Rails.application.routes.url_helpers.send(Auth::OmniAuth::Path.show_or_update_or_delete_path(Auth.configuration.product_class),self.id.to_s)
	end
	
end
