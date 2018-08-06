class Auth::Shopping::BarCode
	include Mongoid::Document
	field :resource_id, type: String
	field :resource_class, type: String
	field :assigned_to_object_id, type: String
	field :assigned_to_object_class, type: String
	field :bar_code_tag, type: String
	index({ bar_code_tag: 1 }, { unique: true, name: "bar_code_tag_index" })
		
	## we do this to delet a reference to an object from a bar code.
	def self.clear_object(bar_code_tag)
		returned_document = collection.where(:bar_code_tag => bar_code_tag).find_one_and_update(
			{
				"$set" => {
					"resource_id" => nil,
					"resource_class" => nil,
					"assigned_to_object_id" => nil,
					"assigned_to_object_class" => nil
				}
			},
			{
				:return_document => :after
			}
		)
		true if returned_document.assigned_to_object_id == nil
	end

	## the object here must be implementing the bar code concern.
	## what if another bar code has this object on it?
	## now two barcodes refer to the same object, and we have no way of catching that
	## so the 
	def self.upsert_and_assign_object(object)
		returned_document = collection.where(
			"$or" => [
						{
							:bar_code_tag => bar_code_tag
						},
						{
							:assigned_to_object_id => object.id.to_s,
							:assigned_to_object_class => object.class.name.to_s
						}
					]
			).find_one_and_update(
			{
				"setOnInsert" => {
					"resource_id" => object.resource_id,
					"resource_class" => object.resource_class,
					"assigned_to_object_id" => object.id.to_s,
					"assigned_to_object_class" => object.assigned_to_object_class,
					"bar_code_tag" => object.bar_code_tag	
				}
			},
			{
				:returned_document => :after,
				:upsert => true
			}
		)
		
		false unless returned_document

		false if returned_document.assigned_to_object_id != object.id.to_s

		false if returned_document.bar_code_tag != object.bar_code_tag

		## as long as all this is satisfied, it means that there is either already this bar code assigned to this object, or 

		true

	end

end