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

	##########################################################
	##
	##
	## SCHEDULing specifications and fields.
	##
	##
	##########################################################

		## we need to provide time based information for scheduling this step
		######################################################
		##
		##
		## TIME BASED FIELDS
		##
		## ALL NUMBERING ON TIME BASED FIELDS STARTS WITH 
		##
		######################################################

		## this will be different for different product_ids.
		## there will have to be a switch which says it can just follow the previous step.


		## what is the location ?
		## a direct id or a location category.
		## or what ?
		## sometimes it has to be inferred, like the previous location of the product.
		## we can have a location lookup?
		## for the moment its category -> and that will default to searching for the nearest location based on a category

		## or it can just have a switch called previous, which is the default, in which case, it just follows the earlier step.
		


		## we need to provide location based information for doing this step


		## we need to provide 

	##########################################################
	##
	##
	##
	##
	##
	##########################################################

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


	#########################################################
	## 
	## CALLED FROM:
	## 
	## BEFORE_SCHEDULE_ORDER  
	##
	##
	########################################################

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

	def resolve_requirements
		## first let me start by creating some simple json objects
		## okay how to assess for requirements.
		## basically the sop is going to always define a requirement category
		## so when that requirement is searched for we are looking for something with a
	end
		
	## if this step is made applicable, it must have either a duration or a duration calculation function.
	def duration_or_duration_calculation_function_exists

		if self.applicable_changed? && self.applicable == true
			self.errors.add(:duration,"please specify a duration or a duration calculation function") if (self.duration.blank? && self.duration_calculation_function.blank?)
		end

	end


end


