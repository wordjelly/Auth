class Auth::Workflow::Minute

	include Mongoid::Document

	embedded_in :location, :class_name => Auth.configuration.location_class

	## the minimum duration of all the entities embedded in this minute.
	field :minimum_entity_duration, type: Integer

	## an integer is assigned to every minute from 0 -> 1439 for 11.59
	field :minute, type: Integer

	## this tells the exact hour and minute that this minute represents.
	field :hour_description, type: String

	embeds_many :categories, :class_name => Auth.configuration.category_class
	
	embeds_many :consumables, :class_name => Auth.configuration.consumable_class

	attr_accessor :location

	## @param[String] query_id : the id of the query.
	def minute_to_insert(query_id)
		
		
		hash_to_insert = {:consumables => {}, :categories => {}}
		
		self.consumables.each do |consumable|
			hash_to_insert[:consumables][consumable.product_id] = 
			[
				{
					:quantity => consumable.quantity,
					:query_ids => [query_id] 
				}
			]
		end

		x = self.categories.map{|c| c = c.category}
		
		category_combination = self.categories.map{|c| c = c.category}.join("_")

		hash_to_insert[:categories][category_combination.to_sym] = {}

		hash_to_insert[:categories][category_combination.to_sym] = {:category_names => category_combination.split("_"), :query_ids => {query_id.to_sym => {}}}
		
		self.categories.each do |category|
			hash_to_insert[:categories][category_combination.to_sym][:query_ids][query_id.to_sym][category.category.to_sym] = {}
			category.entities.each do |entity|
				entity_type = entity.get_type
				hash_to_insert[:categories][category_combination.to_sym][:query_ids][query_id.to_sym][category.category.to_sym][entity_type.to_sym] = 1
			end
		end

		

		hash_to_insert

	end

	## category -> {type : amount_existing}
	def get_category_entity_types
		response = {}
		self.categories.each do |category|
			response[category.category.to_sym] = {}
			category.entities.each do |entity|
				entity_type = entity.get_type
				if entity_type == "default"
					response[category.category.to_sym] = {entity_type.to_sym => category.capacity}
				else
					response[category.category.to_sym] = {entity_type.to_sym => entity.transport_capacity}
				end
			end
		end
		response
	end

	def get_categories_to_capacity
		self.categories.map{|c| c = [c.category,c.capacity]}.to_h
	end

	def get_consumable_to_quantity
		self.consumables.map{|c| c = [c.product_id,c.quantity]}.to_h unless self.consumables.empty?
	end

	
	

end