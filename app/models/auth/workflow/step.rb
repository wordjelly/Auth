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
			
			puts self.location_information if !self.location_information.blank?

			puts self.time_information if !self.time_information.blank?
			## now for each requirement of this step do the same, as long as the requirement is applicable.
			self.requirements.each_with_index{|requirement,key|
				if requirement.applicable
					
					requirement_location_information = first_cart_item.location_information["stages:#{stage_index}:sops:#{sop_index}:steps:#{step_index}:requirements:#{key}"]
						
					requirement.location_information = requirement.location_information.merge(requirement_location_information) if !requirement_location_information.blank?

					requirement_time_information = first_cart_item.time_information["stages:#{stage_index}:sops:#{sop_index}:steps:#{step_index}:requirements:#{key}"]
					
					requirement.time_information = requirement.time_information.merge(requirement_time_information) if !requirement_time_information.blank?


				end
			}

		end

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

	########################################################

	## what should be the structure of the location hash?
	## is it going to carry information about individual requirements.
	## what kind of location requirements are possible?
	##
	##
	## location_type : hematology_station/collection_center/biochemistry_center
	## near_point : [lat,lon]
	## resolve_location : true/false
	## if there are n machines, then we have to resolve them at this stage or not ?
	## requirement can also have something called resolve_requirement
	## so suppose we want to resolve the requirement, then we have a category -> merge that with the location information hash, and find a requirement.
	## now suppose we had more than one requirement, then ?
	## does everything in a step happen at the same location information?
	## because then we can send one query.
	## near location => x and location_category = [z,q]
	## so we will have to have location objects.
	## so these location categories, okay suppose we resolve a nearest location.
	## now we want to search for machines in the final schedule with that.
	## there is no other way is there.
	## so we can search for something on which those requirement categories are registered.
	## if the requirement doesnt have its own location information, then the step location information is used.
	## if the requirement has resolve requirement -> then resolve it.
	## why resolve ? because it is used somewhere in the front.
	## why resolve_requirement ?

	## suppose we had additioanl requirements with this, then what could we do?
	## so would you superimpose this on the requiremenets, for the purpose of scheduling, yes of course, would have to do that.
	## something like machine category x, then we have to immediately resolve.
	## we take the nearest one.
	## suppose we have n machines.
	## then we take which one?
	## do we make a seperate query for each machine ?
	## how to superimpose the location requirements?
	## basically if any subsequent step is dependent on a requirement attribute from a previous step or set of steps, then that previous step has to be resovled first.
	## so how does this work, exactly.
	## i think what i'm missing here is dependency management.
	## eg : step 4 -> requirements => machine => resolved in one.
	## location => resolved in step 2 
	## time => 


end


