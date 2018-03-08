class Auth::Workflow::Stage
	include Mongoid::Document
	include Auth::Concerns::OwnerConcern
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
		[{:stage => [:name,:description,:assembly_id,:assembly_doc_version,:doc_version,:stage_index]},:id]
	end


	def create_with_conditions(params,permitted_params,model)
		## in this case the model is a stage model.
		return false unless model.valid? 
		assembly_updated = Auth.configuration.assembly_class.constantize.where({
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

		#puts assembly_updated.attributes.to_s
		#puts assembly_updated.stages.to_s

		return false unless assembly_updated
		return model


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