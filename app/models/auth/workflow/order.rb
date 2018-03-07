class Auth::Workflow::Order
	include Mongoid::Document
  	include Auth::Concerns::OwnerConcern

	field :product_ids, type: Array

	## "1 => add"
	## "0 => cancel"
	field :action, type: Integer

	## result, is updated depending, upon whether it was added or deleted.

	#"requirement_satisfied/requirement_insufficient/scheduling/scheduled/failed_to_schedule"
	# we can have background jobs looking for stuff where requirement is satisfied and update it to scheduling.
	# scheduling, will take all the product ids together.
	# and rebuild the schedule ?
	# or modify the existing one ?
	# no it will create a new schedule, and has to cancel the older schedule.
	# so first issue cancellation request to all previous schedules in this sop.
	# then schedule this one.
	# now how are the product ids.
	# but sometimes we have two parallel schedules running, since we may need to backtrack to a entry point to schedule an additional test.
	# so in that case, the requirement will not be satisfied
	# but wherever the requirement is satisfied, it will work.
	# this will be internally set.
	# so how to permit multiple parallel schedules?
	# read only

	## 0 => checking_requirements
	## 1 => requirement_not_satisfied
	## 2 => requirement_satisfied
	## 3 => scheduling
	## 4 => scheduled
	## 5 => could not schedule
	field :status, type: String

	## array of schedules.
	## how will you calculate next step.
	## that is to be based on the exit code
	## there may be a need for dynamic scheduling as well.
	## these will also be internally set.
	## read only, assigned from internal api.
	field :schedules, type: String

	attr_accessor :assembly_id
	attr_accessor :assembly_doc_version
	attr_accessor :stage_index
	attr_accessor :stage_doc_version
	attr_accessor :stage_id
	attr_accessor :sop_index
	attr_accessor :sop_doc_version
	attr_accessor :sop_id
	attr_accessor :order_index


	validate :sop_can_process_order

	validates :action, numericality: { only_integer: true, greater_than_or_equal_to: 0, less_than_or_equal_to: 1 }
	
	validates :status, numericality: { only_integer: true, greater_than_or_equal_to: 0, less_than_or_equal_to: 4}, allow_nil: true
		
	validate do |order|
		order.schedules.each do |schedule_id|
			errors.add(:schedules,"the schedule must be a valid bson object") unless BSON::ObjectId.legal?(schedule_id)
		end
	end
	#########################################################
	##
	##
	##
	## CLASS METHODS.
	##
	##
	########################################################

	def self.find_self(id,signed_in_resource,options={})
  		#puts "the id is: #{id}"
		return nil unless collection =  Auth.configuration.assembly_class.constantize.where("stages.sops.orders._id" => BSON::ObjectId(id)
		)

		collection.first

	end

	def self.permitted_params
		[{:order => [:action,:assembly_id,:assembly_doc_version,:stage_id, :stage_doc_version, :stage_index, :sop_id, :sop_doc_version, :sop_index, :doc_version, :order_index,{:product_ids => []}]},:id]
	end



	##########################################################
	##
	##
	##
	## CALLBACKS
	##
	##
	##
	##########################################################
	

	##########################################################
	##
	##
	##
	## CUSTOM DEFS 
	##
	##
	##
	##########################################################
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
					"stages.#{stage_index}.sops.#{sop_index}.orders" => model.attributes
				}
			},
			{
				:return_document => :after
			}
		)

		

		return false unless assembly_updated
		return model

	end

	def sop_can_process_order
		## the errors are added inside sop.can_process_order
		get_sop.can_process_order(self)
	end

	##########################################################
	##
	##
	##
	## PRIVATE DEFS
	##
	##
	##
	###########################################################
	
	private

	def get_sop
		begin
			#puts "self sop id is : #{self.sop_id}"
			#sop = Auth.configuration.sop_class.constantize.find(self.sop_id)
			## so we want to get the sop.
			## we get the assembly, and then return the sop
			## using the indices.
		rescue Mongoid::Errors::DocumentNotFound
			puts "document was not found."
			nil
		end
	end

end

## can you modify it?
## if it has already been scheduled?
## once order is added, it cannot be modified or deleted
## a product id can be marked for deletion, 
## but here only it has to call all the callbacks.
