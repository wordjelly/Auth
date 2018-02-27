class Auth::Workflow::Step
	include Mongoid::Document
	embedded_in :sop, :class_name => "Auth::Workflow::Sop"
	field :name, type: String, default: nil

	

	def self.find_self(id,signed_in_resource,options={})

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
		  
	end

end

