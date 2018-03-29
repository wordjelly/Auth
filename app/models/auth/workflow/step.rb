class Auth::Workflow::Step
	
	include Auth::Concerns::WorkflowConcern
	
	FIELDS_LOCKED_AFTER_ORDER_ADDED = ["applicable"]
	
	embedded_in :sop, :class_name => Auth.configuration.sop_class

	embeds_many :requirements, :class_name => Auth.configuration.requirement_class

	# this is not needed, since the the tlocation information is same for all the products/inside an sop at every step.
	#embeds_many :tlocations, :class_name => Auth.configuration.tlocation_class
		
	field :time_information, type: Hash

    field :location_information, type: Hash

    field :follows_previous_step, type: Boolean

	field :name, type: String
	field :description, type: String

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
	def modify_tlocation_conditions_for_each_product(order,stage_index,sop_index,step_index)

		## if the current step location hash points to a previosu step, dont do anything
		## same for time
		## otherwise -> 
		## get the location hash from the first cart_item. -> remember all cart items added to an sop have to have the same location hash, time hash.
		## use the stage, sop, and step indexes to check if there are any variables in the tlocation_variables for this step.
		## merge these
		## store the result in the location_information and time_information objects.


	end
	########################################################
	########################################################
	 
	## now at the time of calculating, the actual schedule hash here are the series of steps.


	## take the first step
	## resolve_requirements_immediately ?
	## if yes
		## do the query with the location and time information as modified in the before_schedule_order definition.
		## execute the custom resolve_requirements by calling (eval)
		## now proceed to calculate the duration.
		## if calculate duration expression is provided, then give it all the arguments, from location(which was already modified before), and also the requirement_ids resolved if at all.

	## else
	## add the requirement category to a hash[A], use the start time form the time hash, and increment the duration counter inside the value of the hash[A] by duratino fo the step.

	## go to the next step.
	## do same as above.
	## if the requirement category points to the previous step, just add it to the hash[A] under that category, as long as enforce location is false, if enforce location is new, or it doesnt point to that category, then create a new entry in Hash a, with the new location also added into the value of hash[A] for this new entry.

	## finally we can call query for this whole thing.



end


