class Auth::Workflow::Step
	include Mongoid::Document
	include Auth::Concerns::OwnerConcern
	embedded_in :sop, :class_name => "Auth::Workflow::Sop"
	field :name, type: String, default: nil
	attr_accessor :assembly_id
	attr_accessor :assembly_doc_version
	attr_accessor :stage_index
	attr_accessor :stage_doc_version
	attr_accessor :stage_id
	attr_accessor :sop_index
	attr_accessor :sop_doc_version
	attr_accessor :sop_id

	def self.permitted_params
		[{:step => [:name,:description,:assembly_id,:assembly_doc_version,:stage_id, :stage_doc_version, :stage_index, :sop_id, :sop_doc_version, :sop_index, :doc_version]},:id]
	end
	

	def self.find_self(id,signed_in_resource,options={})
		
		return nil unless collection =  Auth.configuration.assembly_class.constantize.where("stages.sops.steps._id" => id
		)

		collection.first
		  
	end

	def create_with_conditions(params,permitted_params,model)
		## in this case the model is a stage model.
		return false unless Auth.configuration.assembly_class.where
		({
			"$and" => [
				{
					"stages.#{model.stage_index}._id" => model.stage_id
				},
				{
					"stages.#{model.stage_index}.doc_version" => model.stage_doc_version
				},
				{
					"_id" => model.assembly_id
				},
				{
					"doc_version" => model.assembly_doc_version
				},
				{
					"stages.#{model.stage_index}.#{model.sop_index}._id" => model.sop_id
				},
				{
					"stages.#{model.stage_index}.#{model.sop_index}.doc_version" => model.sop_doc_version
				},
			]
		})
		.find_one_and_update(
			{
				"$push" => 
				{
					"stages.#{stage_index}.#{sop_index}" => model.attributes
				}
			},
			{
				:return_document => :after
			}
		)
	end

end


=begin
		results = Auth.configuration.assembly_class.constantize.collection.aggregate(
		      [
		          {
		            "$match" => {
		              "stages.sops.steps._id" => BSON::ObjectId(id)
		            }
		          },
		          {
		            "$unwind" => "$stages"
		          },
		          {
		            "$unwind" => "$stages.sops"
		          },
		          {
		            "$unwind" => "$stages.sops.steps"
		          },
		          {
		            "$match" => {
		              "stages.sops.steps._id" => BSON::ObjectId(id)
		            }
		          }
		      ]
		    )

			return nil if (results.size == 0 || results.size > 1)

			return Mongoid::Factory.from_db(Auth.configuration.assembly_class.constantize,results[0])
=end

