class Auth::Workflow::Stage
	include Mongoid::Document
	embeds_many :sops, :class_name => "Auth::Workflow::Sop"
	embedded_in :assembly, :class_name => "Auth::Workflow::Assembly"
	field :name, type: String

	

	def self.find_self(id,signed_in_resource,options={})

		results = Auth.configuration.assembly_class.constantize.collection.aggregate(
		      [
		          {
		            "$match" => {
		              "stages._id" => BSON::ObjectId(id)
		            }
		          }
		      ]
		    )

			return nil if (results.size == 0 || results.size > 1)

			return Mongoid::Factory.from_db(Auth.configuration.assembly_class.constantize,results[0])
		  
	end


	def self.permitted_params
		[{:stage => [:name,:description,:assembly_id,:assembly_version]},:id]
	end

	
end
