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
		
		cart_items.each do |cart_item|
	
			self.time_information[cart_item.id.to_sym] = {}

			if specification = cart_item.get_specification(self.stage_index.to_s + "_" + self.sop_index.to_s + "_" + self.step_index.to_s)

				self.time_information[cart_item.id.to_sym].merge({:start_time_range => specification.start_time_range})
				
				self.location_information[cart_item.id.to_sym].merge(specification.location)
				
			end

		end

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


