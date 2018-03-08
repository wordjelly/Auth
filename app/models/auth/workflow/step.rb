class Auth::Workflow::Step
	include Mongoid::Document
	include Auth::Concerns::OwnerConcern
	embedded_in :sop, :class_name => Auth.configuration.sop_class
	embeds_many :requirements, :class_name => Auth.configuration.requirement_class
	
	field :name, type: String
	field :description, type: String
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
		[{:step => [:name,:description,:assembly_id,:assembly_doc_version,:stage_id, :stage_doc_version, :stage_index, :sop_id, :sop_doc_version, :sop_index, :doc_version, :step_index]},:id]
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

	## @param[Array] array of Auth::Workflow::Order or implementing class objects.
	## @return[Boolean] true/false, depending on whether the requirements of this step can be satisfied to process the orders in the array
	## the last order is queried to see if previous orders are to be considered in combination with it, or it is to be considered in isolation.
	def check_requirements(orders)
		product_ids = get_product_ids_for_step(orders)
		## now check the requirements.
		## for this we have to first call build_requirement
		## then call compare on the built requirement.
		## now run the damn shit.
		
	end



	## @param[Array] array of order objects
	def get_product_ids_for_step(orders)
		## collect orders from the first one till it reaches one where the combine was false, otherwise gather all, remove duplicats, and then 
		orders_to_be_combined = []
		orders.map{|c|
			orders_to_be_combined.clear unless c.combine
			orders_to_be_combined << c unless c.order_is_cancellation?
		}
		product_ids = orders_to_be_combined.map{|c| c = c,product_ids}.uniq
	end

	def set_instructions(orders)

	end

end


