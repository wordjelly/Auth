class Auth::Workflow::Sop
  	include Mongoid::Document
  	embeds_many :steps, :class_name => "Auth::Workflow::Step"
  	embedded_in :stage, :class_name => "Auth::Workflow::Stage"
  	field :name, type: String

  	## Auth::Workflow::Sop.find_self("5a94f4e9421aa923db33693e",nil,{:stage_id => "5a94f4e9421aa923db336935"})
  	def self.find_self(id,signed_in_resource,options={})

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
		
		k["stages"]["sops"] = [k["stages"]["sops"]]
		
		k["stages"] = [k["stages"]]

		assembly = Mongoid::Factory.from_db(Auth.configuration.assembly_class.constantize,k)
		
		assembly.stage_index = k["stage_index"]
		
		assembly.sop_index = k["sop_index"]
		
		assembly

	end

end
