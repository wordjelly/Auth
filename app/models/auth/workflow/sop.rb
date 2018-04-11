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
		
		product_ids = options[:product_ids]
		assembly_id = options[:assembly_id]


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
			      "stages.sops.sop_doc_version" => "$stages.sops.doc_version",
			      "stages.sops.assembly_id" => "$_id",
			      "stages.sops.sop_id" => "$stages.sops._id",
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

				Mongoid::Factory.from_db(Auth.configuration.sop_class.constantize,sop_hash)
			}

			## now emit create_order events.
			events = []
			applicable_sops.each do |sop|
				options_for_next_event = options.merge(sop.attributes)
				options_for_next_event.deep_symbolize_keys!
				e = Auth::Transaction::Event.new
				e.arguments = options_for_next_event
				e.object_class = Auth.configuration.assembly_class
				e.method_to_call = "create_order_in_sop"
				e.object_id = sop["assembly_id"].to_s
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
			puts "order was not created and checking if any past order already has these cart items?"
			return nil unless has_order_with_cart_items(order)
			puts "it seems it does, so now doing after_create_order."
			return after_create_order(order)
		end

	end

	## @return[Array] : array of Auth::Transaction::Event Objects.
	## the event points to the schedule order function.
	## is called from assembly.
	def after_create_order(order)
		puts "came to after_create order."
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

	

	## @params[Hash] arguments : this event is triggered from the mark_requirement when the last requirement for this sop is marked.
	def schedule_order(arguments={})
		
		## this is incremented after each step, by the duration of the step in seconds.
		duration_after_start_in_seconds = 0

		step_counter = 0

		requirement_hash_to_schedule = {}


		## in order to get the stage_index, sop_index, we will have to perform an aggregation, and get those values.
		self.steps.each_with_index{|step,key|

			if step.applicable
			

				## first it uses the variables sent in with the cart items to modify the location and time requirements of the step itself and also the requirements of the step.
				step.modify_tlocation_conditions_for_each_product(self.orders.last,self.stage_index,self.sop_index,key)

				## resolves the step location and time.
				step.resolve_location(self.steps[key-1].location_information)

				step.resolve_time(self.steps[key-1].time_information)

				step.requirements.each_with_index{|req,req_key|

					if req.applicable && req.schedulable
						
						## will first assign the steps location information to the requirement, and then resolve the requirement_location.
						req.resolve_location(self.location_information,self.time_information,self.resolved_location_id,self.resolved_time)

						## will first assign the steps time information to the requirement, and then resolve the requirement_time.
						req.resolve_time(self.location_information,self.time_information,self.resolved_location_id,self.resolved_time)
					
					end

				}
				
				## now calculates the steps duration.

				step.calculate_duration

				## will add this duration to the duration_after_start.
				duration_after_start_in_seconds += (step.calculated_duration || step.duration)
				

				step.requirements.each_with_index{|req,req_key|

					if req.applicable && req.schedulable
						
						## adds the duration since the first step to the start_time and end_time of the requirement.
						req.add_duration_since_first_step(duration_after_start_in_seconds)

						## adds the step duration to the end_time.
						req.add_duration_from_step(self.calculated_duration || self.duration)
							
						## will create a new entry in the query hash for this requirement, or will add this requirement to a reference requirement, if the parameter :follow_reference_requirement is true.
						## basically it means that this requirmenet is continuing across multiple steps.
						## so we just add to the duration of the previous step from where it was required.
						req.add_to_query_hash(stage_index,sop_index,step_index,req_index,requirement_hash_to_schedule,(self.resolve || req.resolve))
						
					end
				}

				step_counter += 1
			end
		}

		## now builds the query.

		query = {"$or" => []}

		requirement_hash_to_schedule.keys.each do |requirement_address|

			req = requirement_hash_to_schedule[requirement_address]

			req.build_query(query)

		end

	end


end


