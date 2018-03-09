class Auth::Workflow::Order

	include Mongoid::Document
  	include Auth::Concerns::OwnerConcern

  	embedded_in :sop, :class_name => Auth.configuration.sop_class
  	
  	embeds_many :consumables, :class_name => Auth.configuration.consumable_class


	field :product_ids, type: Array

	## "1 => add"
	## "0 => cancel"
	field :action, type: Integer



	## 0 => checking_requirements
	## 1 => requirement_not_satisfied
	## 2 => requirement_satisfied
	## 3 => scheduling
	## 4 => scheduled
	## 5 => could not schedule
	field :status, type: String

	
	field :schedules, type: String


	field :combine, type: Boolean

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

	validates_presence_of :combine
		
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

	## @return[Auth::Workflow::Assembly] an instance of the Assembly object that contains this order.
	## this is used during update/show/delete
	def self.find_self(id,signed_in_resource,options={})
  		
		return nil unless collection =  Auth.configuration.assembly_class.constantize.where("stages.sops.orders._id" => BSON::ObjectId(id)
		)

		## before create order, 
		## we want to see if the sop can do this or not.
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
		## in this case the model is an order model.
		
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

	## returns true if status is "checking_requirements" or "scheduling"
	def pending
		self.status == 0 || self.status == 3 
	end

	def failed_to_schedule
		self.status == 5
	end


	def order_is_cancellation?
		self.action == 0
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
			assembly = Auth.configuration.assembly_class.find(self.assembly_id)
			assembly.stages[self.stage_index].sops[self.sop_index]
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
