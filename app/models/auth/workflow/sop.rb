class Auth::Workflow::Sop
  	include Mongoid::Document
  	embeds_many :steps, :class_name => "Auth::Workflow::Step"
  	embedded_in :stage, :class_name => "Auth::Workflow::Stage"
  	field :name, type: String

  	## Auth::Workflow::Sop.find_self("5a94f4e9421aa923db33693e",nil,{:stage_id => "5a94f4e9421aa923db336935"})
  	def self.find_self(id,signed_in_resource,options={})
  		
		return nil unless collection =  Auth.configuration.assembly_class.constantize.where("stages.sops._id" => id
		)

		collection.first

	end

	def self.permitted_params
		[{:sop => [:name,:description,:assembly_id,:assembly_doc_version,:stage_id,:stage_doc_version,:stage_index]},:id]
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
				}
			]
		})
		.find_one_and_update(
			{
				"$push" => 
				{
					"stages.#{stage_index}" => model.attributes
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
		              "stages.sops._id" => BSON::ObjectId(id)
		            }
		          },
		          {
		            "$unwind" => {
		            	"path" => "$stages",
		            	"includeArrayIndex" => "stage_index"
		            }
		          },
		          {
		            "$unwind" => {
		            	"path" => "$stages.sops",
		            	"includeArrayIndex" => "sop_index"
		            }
		          },
		          {
		            "$match" => {
		              "stages.sops._id" => BSON::ObjectId(id)
		            }
		          }
		      ]
		    
		    )

		return nil if (results.count == 0 || results.count > 1)

		k = results.first
		
		## due to unwinding the sops , stages become hashes, need to be converted into arrays.

		k["stages"]["sops"] = [k["stages"]["sops"]]
		
		k["stages"] = [k["stages"]]

		assembly = Mongoid::Factory.from_db(Auth.configuration.assembly_class.constantize,k)
		

		## have to assign the stage_index and sop_index because these are projected fields, and we have them as attr_accessors, Mongoid::Factory.from_db does not set attr_accessors.
		assembly.stage_index = k["stage_index"]
		
		assembly.sop_index = k["sop_index"]
		
		assembly
=end