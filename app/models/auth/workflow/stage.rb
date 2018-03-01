class Auth::Workflow::Stage
	include Mongoid::Document
	embeds_many :sops, :class_name => "Auth::Workflow::Sop"
	embedded_in :assembly, :class_name => "Auth::Workflow::Assembly"
	field :name, type: String

	

	def self.find_self(id,signed_in_resource,options={})
		return nil unless collection =  Auth.configuration.assembly_class.constantize.where("stages._id" => id
		)
		collection.first
	end

	def self.permitted_params
		[{:stage => [:name,:description,:assembly_id,:assembly_doc_version]},:id]
	end


	def create_with_conditions(params,permitted_params,model)
		## in this case the model is a stage model.
		return false unless Auth.configuration.assembly_class.where
		({
			"$and" => [
				{
					:_id => model.assembly_id
				},
				{
					:doc_version => model.assembly_doc_version
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



	end


	
end

=begin
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
=end		 