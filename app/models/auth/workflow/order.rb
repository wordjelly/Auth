class Auth::Workflow::Order

	include Mongoid::Document
  	include Auth::Concerns::OwnerConcern

  	embedded_in :sop, :class_name => Auth.configuration.sop_class
  	
	field :cart_item_ids, type: Array


	## "1 => add"
	## "0 => remove"
	field :action, type: Integer


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


	validates :action, numericality: { only_integer: true, greater_than_or_equal_to: 0, less_than_or_equal_to: 1 }
	
	field :name, type: String
	
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

		
		collection.first

	end

	def self.permitted_params
		[{:order => [:action,:assembly_id,:assembly_doc_version,:stage_id, :stage_doc_version, :stage_index, :sop_id, :sop_doc_version, :sop_index, :doc_version, :order_index, :name,{:cart_item_ids => []}]},:id]
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
	## the order is created inside the sop, only if the cart items of the order are not present in any prior order, inside the same sop.
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
				{
					"stages.#{model.stage_index}.sops.#{model.sop_index}.orders.cart_item_ids" => {
						"$nin" => model.cart_item_ids
					}
				}
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


	



	


end

