class Auth::Workflow::Step
	
	include Auth::Concerns::WorkflowConcern
	
	FIELDS_LOCKED_AFTER_ORDER_ADDED = ["applicable"]
	
	embedded_in :sop, :class_name => Auth.configuration.sop_class

	embeds_many :requirements, :class_name => Auth.configuration.requirement_class

	# this is not needed, since the the tlocation information is same for all the products/inside an sop at every step.
	#embeds_many :tlocations, :class_name => Auth.configuration.tlocation_class


    field :follows_previous_step, type: Boolean

	field :name, type: String
	field :description, type: String

	validate :duration_or_duration_calculation_function_exists

	## and array of the type :
	## [[1,1],[1,2],[1,3]] : the first element of every sub array is the day_id, and the last element is the minute.
	field :start_minute_list, type: Array, default: []

	field :resolved_location_id, type: String

    field :resolved_time, type: Integer

    field :calculated_duration, type: Integer

    field :duration, type: Integer

    ## we need to provide a duration calculation function here.
    field :duration_calculation_function, type: String, default: ""

    field :category, type: Array, default: []

    field :resolved_id, type: String

    field :resolve, type: Boolean, default: false

	attr_accessor :assembly_id
	attr_accessor :assembly_doc_version
	attr_accessor :stage_index
	attr_accessor :stage_doc_version
	attr_accessor :stage_id
	attr_accessor :sop_index
	attr_accessor :sop_doc_version
	attr_accessor :sop_id
	attr_accessor :step_index
	

	attr_accessor :query_information

	def self.permitted_params
		[{:step => [:name, :applicable, :description,:assembly_id,:assembly_doc_version,:stage_id, :stage_doc_version, :stage_index, :sop_id, :sop_doc_version, :sop_index, :doc_version, :step_index]},:id]
	end
	

	def self.find_self(id,signed_in_resource,options={})
		
		return nil unless collection =  Auth.configuration.assembly_class.constantize.where("stages.sops.steps._id" => BSON::ObjectId(id)
		)

		collection.first
		  
	end

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
					"stages.#{model.stage_index}.sops.#{model.sop_index}._id" => BSON::ObjectId(model.sop_id)
				},
				{
					"stages.#{model.stage_index}.sops.#{model.sop_index}.doc_version" => model.sop_doc_version
				},
			]
		})
		.find_one_and_update(
			{
				"$push" => 
				{
					"stages.#{stage_index}.sops.#{sop_index}.steps" => model.attributes
				}
			},
			{
				:return_document => :after
			}
		)

		

		return false unless assembly_updated
		return model

	end


	def merge_cart_item_specifications(cart_items)

		current_time = Time.now

		_time = {}
		_only_location_cart_items = {}
		
		## here the problem is that we have to add a start time, that is consistent for all the specifications at the minimum
		## while entering the step.

		cart_items.each do |cart_item|
			puts "doing cart item: #{cart_item.id.to_s}"
			if specification = cart_item.get_specification(self.stage_index.to_s + ":" + self.sop_index.to_s + ":" + self.step_index.to_s)

				if start_time_range = specification.start_time_range(current_time)
					puts "has start time range."
					_time[Base64.encode64(start_time_range.to_s)] = {:sort_key => start_time_range[:start_time_range_beginning], :start_time_range => start_time_range, :any_location => {}} unless _time[Base64.encode64(start_time_range.to_s)]

					if loc = specification.location
					
						
						
						_time[Base64.encode64(start_time_range.to_s)][Base64.encode64(loc.to_s)] = {:location => loc, :cart_item_ids => []} unless _time[Base64.encode64(start_time_range.to_s)][Base64.encode64(loc.to_s)]
						
						_time[Base64.encode64(start_time_range.to_s)][Base64.encode64(loc.to_s)][:cart_item_ids] << cart_item.id.to_s
						
					else
						
						if _time[Base64.encode64(start_time_range.to_s)][:any_location][:cart_item_ids]
							
							puts "any location cart item ids already exist."

							_time[Base64.encode64(start_time_range.to_s)][:any_location][:cart_item_ids] << cart_item.id.to_s

						else

							puts "they dont exist."
							
							_time[Base64.encode64(start_time_range.to_s)][:any_location][:cart_item_ids] = [cart_item.id.to_s]
						
						end

					end
											
				else
					if loc = specification.location
						
						_only_location_cart_items[Base64.encode64(loc.to_s)] = {:cart_item_ids => [], :location => loc.to_s} unless _only_location_cart_items[Base64.encode64(loc.to_s)]

						_only_location_cart_items[Base64.encode64(loc.to_s)][:cart_item_ids] << cart_item.id.to_s

					else
					
						## no time information and no location information , will not be performed at all.
					
					end

				end


				
			end

		end

		puts JSON.pretty_generate(_time)

		_time = _time.sort_by{|k,v| v[:sort_key]}.to_h
		## so what to do if there is no sort key.

		_only_location_cart_items.keys.each do |loc|
			found_existing = false
			_time.keys.each do |k|
				unless _time[k][loc].nil?

					#puts "this is _time[k][loc]"
					#puts _time[k][loc]

					#puts "this is only locations cart items"
					#puts _only_location_cart_items[loc][:cart_item_ids]

					_time[k][loc][:cart_item_ids]+= _only_location_cart_items[loc][:cart_item_ids]
					found_existing = true
					break
				end
				unless found_existing
					_time[_time.keys.first][loc] = {:cart_item_ids => _only_location_cart_items[loc][:cart_item_ids]}
				end
			end
		end

		_time

		
	
	end

	def append_time_and_location_information_based_on_previous_step
		## suppose we have the previous step saying some things
		## and now we have 3 cart items here.
		## so they have to be matched to whichever group they belong to.
		## so for that we will have to go over the hash.
		## and then assign them there.
		## based on time since previous query, we have to change the start time ranges.
		## based on the query results.
		## the query will provide a start and an end time.
		## so we will have to hold the minutes from the earlier query for all the cart items.
		## from the previous step.
		## when you come to a step, clear the previous step.
	end

	def do_query

	end

	
	#########################################################
	## 
	## CALLED FROM:
	## 
	## BEFORE_SCHEDULE_ORDER  
	##
	##
	########################################################

	## so for the first step -> it will read from cart_item -> will check if the step itself has some specifications.
	## but for what ?
	## is it necessary ?
	## okay so if defined, then check
	## so that will establish a start_time and end_time_range
	## then there will be a query done
	## that will be fired based on the type of step.
	## so the step has to define which query to fire? 
	## basically if the query is defined for a geopoint.
	## like location is also passed in from the cart_item.
	## like it provides a location.
	## how to distinguish between a situation that needs a target location to be reached, vs a situation where 
	## how to know which entity categories are going to be needed? 
	## that is also to be defined in the step (the so called requirements.)
	## suppose we have given a location. what is this location ? 
	## so if a location id is given, then it is directly provided, otherwise, the location is a nearest location, 
	## so a transport query will have to be defined.
	## for eg : we need an entity,that is nearest to this entity.
	## if a speed is defined, then 
	## see normally we need entities, at a location id, at a specified time. that is our basic query.
	## but in this case, we need them at * location id, nearest to a particular location id, and at a certain speed.

	## so basically the step will define the query type to be used, and ask for certain parameters to be defined, by the cart items.
	
	## so the cart item will have to carry , time information, location information for particular step addresses, and also any additional parameters
	
	## so the product has to have an embedded document.
	## it has a step address:
	## it has a location information hash
	## it has a time information hash
	## it has a additional_parameters_hash
	## all these things are defined in the cart item.
	## so now these parameters will be used in the step to perform the query.

	## @param[Auth::Workflow::Order] order : the latest added order which is being scheduled.
	## @param[Integer] stage_index : the index of the stage
	## @param[Integer] sop_index : the index of the sop
	## @param[Integer] step_index : the index of the step.  
	## what to do incase this step's location information has a reference?
	## and same for requirement ?
	## can a requirement reference a previous step?
	## in that case what sense does it make to add time and location information to it?
	## we don't enforce location.
	## this should only be done if time and locatino are to be enforced, for a particular step.
	## but at this stage, let the merging happen.
	def modify_tlocation_conditions_for_each_product(order,stage_index,sop_index,step_index)
		
		self.location_information.deep_symbolize_keys!
		self.time_information.deep_symbolize_keys!
		#puts "stage index :#{stage_index}"
		#puts "sop index : #{sop_index}"
		#puts "step index: #{step_index}"

		if first_cart_item = Auth.configuration.cart_item_class.constantize.find(order.cart_item_ids.first)

			
			location_information = first_cart_item.location_information["stages:#{stage_index}:sops:#{sop_index}:steps:#{step_index}"]

			time_information = first_cart_item.time_information["stages:#{stage_index}:sops:#{sop_index}:steps:#{step_index}"]


			## merge the information inside it, 
			if !location_information.blank?
				self.location_information = self.location_information.merge(location_information)
			end
			
			if !time_information.blank?
				self.time_information = self.time_information.merge(time_information) 
			end
			
			## the variables if any are added only to the step.
			## the requirements that are noted inside the step , can have only a category.
			## requirements can always have only a category, there is no such thing as a direct requirement id


=begin
			self.requirements.each_with_index{|requirement,key|
				if requirement.applicable
					
					requirement_location_information = first_cart_item.location_information["stages:#{stage_index}:sops:#{sop_index}:steps:#{step_index}:requirements:#{key}"]
						
					requirement.location_information = requirement.location_information.deep_symbolize_keys.merge(requirement_location_information) if !requirement_location_information.blank?

					requirement_time_information = first_cart_item.time_information["stages:#{stage_index}:sops:#{sop_index}:steps:#{step_index}:requirements:#{key}"]
					
					requirement.time_information = requirement.time_information.deep_symbolize_keys.merge(requirement_time_information) if !requirement_time_information.blank?


				end
			}
=end
		end

	end

	
		
	## if this step is made applicable, it must have either a duration or a duration calculation function.
	def duration_or_duration_calculation_function_exists

		if self.applicable_changed? && self.applicable == true
			self.errors.add(:duration,"please specify a duration or a duration calculation function") if (self.duration.blank? && self.duration_calculation_function.blank?)
		end

	end


end


