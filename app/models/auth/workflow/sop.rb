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
		[{:sop => [:name,:description,:assembly_id,:assembly_doc_version,:stage_id,:stage_doc_version,:stage_index,:doc_version, :sop_index, :applicable_to_product_ids]},:id]
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

end


