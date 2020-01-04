class Auth::Workflow::Stage
	
	include Auth::Concerns::WorkflowConcern
	
	FIELDS_LOCKED_AFTER_ORDER_ADDED = ["applicable"]

	embeds_many :sops, :class_name => Auth.configuration.sop_class
	embedded_in :assembly, :class_name => Auth.configuration.assembly_class
	field :name, type: String
	field :description, type: String
	attr_accessor :assembly_id
	attr_accessor :assembly_doc_version
	attr_accessor :stage_index

	

	def self.find_self(id,signed_in_resource,options={})
		return nil unless collection =  Auth.configuration.assembly_class.constantize.where("stages._id" => BSON::ObjectId(id)
		)
		collection.first
	end

	def self.permitted_params
		[{:stage => [:applicable, :name,:description,:assembly_id,:assembly_doc_version,:doc_version,:stage_index]},:id]
	end


	def create_with_conditions(params,permitted_params,model)
		## in this case the model is a stage model.
		
		return false unless model.valid? 
		
		assembly_updated = Auth.configuration.assembly_class.constantize.where({
			"$and" => [
				{
					:_id => BSON::ObjectId(model.assembly_id)
				},
				{
					:doc_version => model.assembly_doc_version
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
					:stages => model.attributes
				}
			},
			{
				:return_document => :after
			}
		)

		#puts assembly_updated.attributes.to_s
		#puts assembly_updated.stages.to_s

		return false unless assembly_updated
		return model


	end


	
end

	 