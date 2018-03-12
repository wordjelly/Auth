class Auth::Workflow::Sop
  	include Mongoid::Document
  	include Auth::Concerns::OwnerConcern
  	embeds_many :steps, :class_name => Auth.configuration.step_class
  	embeds_many :orders, :class_name => Auth.configuration.order_class
  	embedded_in :stage, :class_name => Auth.configuration.stage_class
  	field :name, type: String
  	field :description, type: String
  	field :applicable_to_product_ids, type: Array

  	attr_accessor :assembly_id
	attr_accessor :assembly_doc_version
	attr_accessor :stage_index
	attr_accessor :stage_doc_version
	attr_accessor :stage_id
	attr_accessor :sop_index


  	
  	def self.find_self(id,signed_in_resource,options={})
  		#puts "the id is: #{id}"
		return nil unless collection =  Auth.configuration.assembly_class.constantize.where("stages.sops._id" => BSON::ObjectId(id)
		)

		collection.first

	end

	def self.permitted_params
		[{:sop => [:name,:description,:assembly_id,:assembly_doc_version,:stage_id,:stage_doc_version,:stage_index,:doc_version, :sop_index, {:applicable_to_product_ids => []}]},:id]
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
				}
			]
		})
		.find_one_and_update(
			{
				"$push" => 
				{
					"stages.#{stage_index}.sops" => model.attributes
				}
			},
			{
				:return_document => :after
			}
		)

		#puts "assembly updated is: #{assembly_updated}"

		return false unless assembly_updated

		return model
		
	end

	## so it will look first if those orders are processed or processing or whatever.
	## first we are just checking if previous order is processing.

	def can_process_order(order)

		## FIRST CHECK IF ANY OF THE PREVIOUS ORDERS REQUIREMENTS ARE BEING CHECKED OR IT IS BEING SCHEDULED OR IT COULD NOT BE SCHEDULED

		non_viable_orders = self.orders.select{|c| 
			true if (c.order_pending || c.failed_to_schedule)
		}

		order.errors.add(:status, "another order is being processed, check back later") if non_viable_orders.size > 0


		self.steps.each do |step|
			## now here we will call a method on step.
			
		end

	end

	## @return[Array] array of hashes, each with the following structure:
=begin
{
  "_id": {
    "$oid": "5aa3c9b7421aa90dedf35ff9"
  },
  "stages": {
    "_id": {
      "$oid": "5aa3c9b7421aa90dedf35ffc"
    },
    "public": "no",
    "doc_version": 0,
    "sops": {
      "_id": {
        "$oid": "5aa3c9b7421aa90dedf35ffe"
      },
      "public": "no",
      "doc_version": 0,
      "applicable_to_product_ids": [
        "5aa3c9b7421aa90dedf35ff8"
      ]
    }
  },
  "stage_index": 1,
  "sop_index": 1,
  "matches": [
    "5aa3c9b7421aa90dedf35ff8"
  ]
}
=end
	## it basically returns the stage_index as well as the sop_index alongwith their respective ids.
	## the matches array contains the product ids to which that sop is applicable, out of the product ids supplied.
	def get_applicable_sops_given_product_ids

		## before creating order -> process_step
		## that calls requirement.sufficient? 

		res = Auth.configuration.assembly_class.constantize.collection.aggregate([
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
				"$project" => {
					"common_products" => {
						"$setIntersection" => ["$stages.sops.applicable_to_product_ids",self.applicable_to_product_ids]
					},
					"stages" => 1,
					"sops" => 1,
					"sop_index" => 1,
					"stage_index" => 1
				}
			},
			{
			    "$addFields" => {
			      "stages.sops.sop_index" => "$sop_index",
			      "stages.sops.stage_index" => "$stage_index"
			    }
			},
			{
				"$project" => {
					"stages" => {
						"$cond" => {
							"if" => {
								"$gt" => [
									{"$size" => "$common_products"},
									0
								]
							},
							"then" => "$stages",
							"else" => "$$REMOVE"
						}
					},
					"sop_index" => 1,
					"stage_index" => 1	
				}
			},
			{
				"$group" => {
					"_id" => nil,
					"sops" => { "$push" => "$stages.sops" } 
				}
			}
		])


		## so we want to return an array of SOP objects.

		#res.each do |result|
		#	puts JSON.pretty_generate(result)
		#end

		
		return [] unless res.count > 0

		res.first["sops"].map{|sop_hash|

			Mongoid::Factory.from_db(Auth.configuration.sop_class.constantize,sop_hash)
		}

	end

	def get_many
		get_applicable_sops_given_product_ids
	end

end


