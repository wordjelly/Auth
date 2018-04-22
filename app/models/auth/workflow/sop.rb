class Auth::Workflow::Sop

  	include Auth::Concerns::WorkflowConcern
  	
  	FIELDS_LOCKED_AFTER_ORDER_ADDED = ["applicable"]

  	embeds_many :steps, :class_name => Auth.configuration.step_class
  	embeds_many :orders, :class_name => Auth.configuration.order_class
  	embedded_in :stage, :class_name => Auth.configuration.stage_class
  	field :name, type: String
  	field :description, type: String
  	field :applicable_to_product_ids, type: Array, default: []

  	attr_accessor :assembly_id
	attr_accessor :assembly_doc_version
	attr_accessor :stage_index
	attr_accessor :stage_doc_version
	attr_accessor :stage_id
	attr_accessor :sop_index


	#########################################################
	##
	##
	##
	## CLASS METHODS
	## 
	##
	##
	#########################################################

  	
  	def self.find_self(id,signed_in_resource,options={})
  		#puts "the id is: #{id}"
		return nil unless collection =  Auth.configuration.assembly_class.constantize.where("stages.sops._id" => BSON::ObjectId(id)
		)

		collection.first

	end

	def self.permitted_params
		[{:sop => [:name, :applicable, :description,:assembly_id,:assembly_doc_version,:stage_id,:stage_doc_version,:stage_index,:doc_version, :sop_index, {:applicable_to_product_ids => []}]},:id]
	end


	## @return[Array] array of hashes, each with the following structure:
	## it basically returns the stage_index as well as the sop_index alongwith their respective ids.
	## the matches array contains the product ids to which that sop is applicable, out of the product ids supplied.
	def self.find_applicable_sops(options={})
		
		## instantiate the order object from the serialized hash passed in.

		order = Auth.configuration.order_class.constantize.new(JSON.parse(options[:order]))
		
		## we need to get the product ids , given the cart item ids.
		product_ids = order.cart_item_ids.map{|c|
			cart_item = Auth.configuration.cart_item_class.constantize.find(c)
			c = cart_item.product_id
		}.uniq

		assembly_id = order.assembly_id

		res = Auth.configuration.assembly_class.constantize.collection.aggregate([
			{
				"$match" => {
					"_id" => BSON::ObjectId(assembly_id) 
				}
			},
			{
				"$unwind" => {
					"path" => "$stages",
					"includeArrayIndex" => "stage_index"
				}
			},
			{
				"$unwind" => {
					"path" => "$stages.sops",
					"includeArrayIndex" => "sop_index"
				}
			},
			{
				"$project" => {
					"common_products" => {
						"$setIntersection" => ["$stages.sops.applicable_to_product_ids",product_ids]
					},
					"stages" => 1,
					"sops" => 1,
					"sop_index" => 1,
					"stage_index" => 1,
					"doc_version" => 1,
					"_id" => 1
				}
			},
			{
			    "$addFields" => {
			      "stages.sops.sop_index" => "$sop_index",
			      "stages.sops.stage_index" => "$stage_index",
			      "stages.sops.assembly_doc_version" => "$doc_version",
			      "stages.sops.stage_doc_version" => "$stages.doc_version",
			      "stages.sops.stage_id" => "$stages._id",
			      "stages.sops.doc_version" => "$stages.sops.doc_version",
			      "stages.sops.assembly_id" => "$_id",
			      "stages.sops._id" => "$stages.sops._id",
			      "common_products" => { 
			      		"$ifNull" =>  [ "$common_products", []]
			      	}
			    }
			},
			{
				"$project" => {
					"stages" => {
						"$cond" => {
							"if" => {
								"$gt" => [
									{"$size" => "$common_products"},
									0
								]
							},
							"then" => "$stages",
							"else" => "$$REMOVE"
						}
					},
					"sop_index" => 1,
					"stage_index" => 1	
				}
			},
			{
				"$group" => {
					"_id" => nil,
					"sops" => { "$push" => "$stages.sops" } 
				}
			}
		])


		## so we want to return an array of SOP objects.

		#puts "initial res is:"
		#res.each do |result|
		#	puts JSON.pretty_generate(result)
		#end

		

		#puts "res is :#{res}"

		begin
			return [] unless res
			return [] unless res.count > 0

			applicable_sops = res.first["sops"].map{|sop_hash|

				#puts "sop hash is:"
				#puts JSON.pretty_generate(sop_hash)

				k = Mongoid::Factory.from_db(Auth.configuration.sop_class.constantize,sop_hash)
				k.stage_index = sop_hash["stage_index"]
				k.sop_index = sop_hash["sop_index"]
				k

			}

			## now emit create_order events.
			events = []

			## the important thing at this stage will be to add the relevant information on the order.
			if applicable_sops.size > 0
				#puts "THE FIRST STAGE INDEX IS:"
				#puts applicable_sops.first.stage_index
				#puts "the first sop index is:"
				#puts applicable_sops.first.sop_index
				e = Auth::Transaction::Event.new
				e.arguments = options.merge({:sops => applicable_sops.to_json})
				#puts e.arguments.to_s
				e.object_class = Auth.configuration.assembly_class
				e.method_to_call = "create_order_in_multiple_sops"
				e.object_id = order.assembly_id.to_s
				events << e
			end

			events

		rescue => e
			puts "rescued"
			puts e.to_s
			return nil
		end

	end

	#########################################################
	##
	##
	##
	## INSTANCE METHODS
	## 
	##
	##
	#########################################################	


	def create_with_conditions(params,permitted_params,model)
		## in this case the model is a stage model.

		return false unless model.valid?
		

		assembly_updated = Auth.configuration.assembly_class.constantize.where({
			"$and" => [
				{
					"stages.#{model.stage_index}._id" => BSON::ObjectId(model.stage_id)
				},
				{
					"stages.#{model.stage_index}.doc_version" => model.stage_doc_version
				},
				{
					"_id" => BSON::ObjectId(model.assembly_id)
				},
				{
					"doc_version" => model.assembly_doc_version
				},
				{
					"stages.sops.orders" => {
			            "$exists" => false
			        }
				}
			]
		})
		.find_one_and_update(
			{
				"$push" => 
				{
					"stages.#{stage_index}.sops" => model.attributes
				}
			},
			{
				:return_document => :after
			}
		)

		#puts "assembly updated is: #{assembly_updated}"

		return false unless assembly_updated

		return model
		
	end


	

	## called from #index in authenticated_controller.
	def get_many
		self.class.find_applicable_sops({:product_ids => self.applicable_to_product_ids, :assembly_id => self.assembly_id})
	end

	## return[Boolean] true if the sop already has some order with any of the cart_items in this order.
	def has_order_with_cart_items(order)
		results =Auth.configuration.assembly_class.constantize.where({
			"$and" => [
				{
					"_id" => BSON::ObjectId(order.assembly_id.to_s)
				},
				{
					"stages.#{order.stage_index}.sops.#{order.sop_index}.orders.cart_item_ids" => {
						"$in" => order.cart_item_ids
					}
				}
			]
		})

		return results && results.size == 1
	end

	## @return[Integer] the index in the sop's orders of the given order.
	def get_order_index(order)
		## unwind, and match.
		order_els = Auth.configuration.assembly_class.constantize.collection.aggregate([
				{
					"$match" => {
						"_id" => BSON::ObjectId(order.assembly_id.to_s) 
					}
				},

				{
					"$unwind" => {
						"path" => "$stages",
						"includeArrayIndex" => "stage_index"
					}
				},
				{
					"$unwind" => {
						"path" => "$stages.sops",
						"includeArrayIndex" => "sop_index"
					}
				},
				{
					"$unwind" => {
						"path" => "$stages.sops.orders",
						"includeArrayIndex" => "order_index"
					}
				},

				{
					"$match" => {
						"stages.sops.orders._id" => BSON::ObjectId(order.id.to_s)
					}
				}

			])

		raise "did'nt find the order" unless order_els


		return order_els.first["order_index"]


	end	



	##########################################################
	##
	##
	##
	## defs for events
	##
	##
	##
	##########################################################

	def create_order(arguments={})
		
		#puts "came to create order"
		#puts JSON.pretty_generate(arguments)
		
		return nil if (arguments[:assembly_id].blank? || arguments[:assembly_doc_version].blank? || arguments[:stage_id].blank? || arguments[:stage_index].blank? || arguments[:stage_doc_version].blank? || arguments[:sop_id].blank? || arguments[:sop_index].blank? || arguments[:sop_doc_version].blank?)

		## okay, wtf is this?
		order = Auth.configuration.order_class.constantize.new(:cart_item_ids => arguments[:cart_item_ids],:stage_index => arguments[:stage_index],:stage_id => arguments[:stage_id], :sop_index => arguments[:sop_index], :sop_id => arguments[:sop_id], :assembly_id => arguments[:assembly_id], :assembly_doc_version => arguments[:assembly_doc_version],:sop_doc_version => arguments[:sop_doc_version], :stage_doc_version => arguments[:stage_doc_version], :action => 1)

		if order_created = order.create_with_conditions(nil,nil,order)
			return after_create_order(order_created)
		else
			#puts "order was not created and checking if any past order already has these cart items?"
			return nil unless has_order_with_cart_items(order)
			#puts "it seems it does, so now doing after_create_order."
			return after_create_order(order)
		end

	end

	## @return[Array] : array of Auth::Transaction::Event Objects.
	## the event points to the schedule order function.
	## is called from assembly.
	def after_create_order(order)
		#puts "came to after_create order."
		e = Auth::Transaction::Event.new
		e.arguments = {}
		e.arguments[:sop_index] = order.sop_index
		e.arguments[:stage_index] = order.stage_index
		e.method_to_call = "sop_schedule_order"
		e.object_class = Auth.configuration.assembly_class
		e.object_id = order.assembly_id.to_s	
		[e]
	end


	## this was previously in after_create_order.
	def generate_mark_requirement_events(order)
		
		if get_order_index(order) == 0
			## we want to return an array of events.
			sop_requirements_with_calculated_states = get_sop_requirements(order)
			sop_requirements_with_calculated_states.each_with_index.map{|requirement,i|
				e = Auth::Transaction::Event.new
				e.arguments = {}

				e.arguments[:sop_index] = order.sop_index
				e.arguments[:stage_index] = order.stage_index
				e.arguments[:requirement_index] = i
				e.arguments[:step_index] = requirement.step_index

				e.arguments[:requirement] = requirement.attributes
				if i == (sop_requirements_with_calculated_states.size - 1)
					e.arguments[:last_requirement] = true
					e.arguments[:sop_id] = self.id.to_s
				end
				e.method_to_call = "mark_sop_requirements"
				e.object_class = Auth.configuration.assembly_class
				
				e.object_id = order.assembly_id.to_s	
				requirement = e
			}
		else 
			## do nothing.
		end

	end

	## @return[Array] array of Auth::Workflow::Requirement objects. 
	def get_sop_requirements(order)
		
		requirements_with_calculated_states = []

		steps.each_with_index {|step,step_index|
			step.requirements.each do |requirement|
				requirement.step_index = step_index
				requirement.calculate_required_states(order)
				requirements_with_calculated_states << requirement
			end
		}

		#puts "these are the requirements with calculated states."
		#puts requirements_with_calculated_states.to_s

		requirements_with_calculated_states

	end

	## iterates the cart_items in the last order of this sop, and sees which of them has the latest start time from the provided hash.
	## @param[Hash] cart_items_latest_time : 
	## structure : 
	## 
	##
	## cart_item_id => {:start_time_range => [], :end_time_range => []}
	## 
	## 
	##
	## @return[Hash] : a hash with just one cart item entry in it.

	def last_time_slot_applicable_to_present_cart_items(cart_items_latest_time)

		
		greatest_end_time = nil
		
		cart_items_latest_time.values.each_with_index{|value,key|

			greatest_end_time = value unless greatest_end_time

			if greatest_end_time
				#puts "value is:" 
				#puts value.to_s
				#puts "greatest end time is:"
				#puts greatest_end_time.to_s
				if value[:end_time_range][1] > greatest_end_time[:end_time_range][1]
					greatest_end_time = value
				end
			end

		}

		return greatest_end_time || {}
	end

	## @param[Auth::Workflow::Step] last_step : the last step in the sop.
	## @param[Hash] cart_items_latest_time : the hash of latest time information for each cart_item, passed in from the assembly#schedule_sop_order
	## @return[Hash] cart_items_latest_time : will update the 

	def update_cart_items_latest_time(last_step,cart_items_latest_time)

		if cart_items_latest_time.empty?
			self.orders.last.cart_item_ids.each do |c_id|
				cart_items_latest_time[c_id] = {}
				cart_items_latest_time[c_id][:start_time_range] = last_step.time_information[:start_time_range]
				cart_items_latest_time[c_id][:end_time_range] = last_step.time_information[:end_time_range]
			end
		else
			cart_items_latest_time.keys.each do |c_id|
				if self.orders.last.cart_item_ids.include? c_id
					cart_items_latest_time[c_id][:start_time_range] = last_step.time_information[:start_time_range]
					cart_items_latest_time[c_id][:end_time_range] = last_step.time_information[:end_time_range]
				end
			end	
		end	

		cart_items_latest_time

	end


	## this has to return the cart_items_latest_time, as well as requirement_query_hash
	## both are hashes.
	def schedule_order(cart_items_latest_time, requirement_query_hash)

		latest_ending_cart_item = last_time_slot_applicable_to_present_cart_items(cart_items_latest_time)

		
=begin
--------------------- PREFERRED FLOW OF EVENTS ---------------------

      ## resolve location basically takes the coordinates from a provided location id if at all
      ## resolve time is then fired, it just finalizes the start time.
      ## thereafter -> if resolve is ticked, then requirement query is fired, using the start time, and end time if it is there.
      ## thereafter -> calculate duration is fired, in which the duration if not specified is assigned by using any variables from time_information or location_information.
      ## thereafter -> resolve time is fired, which basically sets the end time equal to the start_time + duration.
      ## then the whole thing is transferred to the requirement query.

--------------------------------------------------------------------
=end


		self.steps.each_with_index{|step,key|

			next unless step.applicable
					
			#puts "the self stage index is: #{self.stage_index}, and self sop index is: #{self.sop_index}"
			step.step_index = key
			step.stage_index = self.stage_index
			step.sop_index = self.sop_index
		
			step.modify_tlocation_conditions_for_each_product(self.orders.last,self.stage_index,self.sop_index,key)

			step.calculate_duration

			## how to set the default time information.
			step.time_information ||= {:minimum_time_since_previous_step => 0, :maximum_time_since_previous_step => 1}
			step.time_information[:minimum_time_since_previous_step] ||= 0
			step.time_information[:maximum_time_since_previous_step] ||= 1
			## done.
			
			step.resolve_location(key > 0 ? self.steps[key-1].location_information : {})
			step.resolve_start_time(key > 0 ? self.steps[key-1].time_information : latest_ending_cart_item)
			step.resolve_requirements if step.resolve
			step.calculate_duration
			step.resolve_end_time

			

			step.requirements.each_with_index{|req,req_key|


				next unless (req.applicable && req.schedulable)	
				
				req.stage_index = step.stage_index
				req.sop_index = step.sop_index
				req.step_index = step.step_index

				
				if req.reference_requirement_address == nil


					requirement_query_hash[req.get_self_address(req_key)] = [{:start_time_range => step.time_information[:start_time_range], :end_time_range => step.time_information[:end_time_range]}]

				elsif requirement_query_hash[req.reference_requirement_address].nil?

					requirement_query_hash[req.get_self_address(req_key)] = [{:start_time_range => step.time_information[:start_time_range], :end_time_range => step.time_information[:end_time_range]}]					

				else 		

					#puts "the reference requirement address is:"
					#puts req.reference_requirement_address.to_s

					#puts "this is the existing requirmenet query hash."
					#puts requirement_query_hash.to_s
					#puts "this is the step time information"
					#puts step.time_information		

					if requirement_query_hash[req.reference_requirement_address].last[:end_time_range] == step.time_information[:start_time_range]

						#puts "end time range of last step is equal to the start time range of this step"

						## now set this as the new hash.
						requirement_query_hash[req.reference_requirement_address][-1] = {:start_time_range => requirement_query_hash[req.reference_requirement_address].last[:start_time_range], :end_time_range => step.time_information[:end_time_range]}

					elsif requirement_query_hash[req.reference_requirement_address].last[:end_time_range][1] < step.time_information[:start_time_range][1]

						#puts "end time range of last step is less than start time range of this step."

						requirement_query_hash[req.reference_requirement_address] << {:start_time_range => step.time_information[:start_time_range], :end_time_range => step.time_information[:end_time_range]}

					end

					
				end

			}
			
		}

		cart_items_latest_time =  update_cart_items_latest_time(self.steps.last,cart_items_latest_time)

		return {:cart_items_latest_time => cart_items_latest_time, :requirement_query_hash => requirement_query_hash}		

	end


end


