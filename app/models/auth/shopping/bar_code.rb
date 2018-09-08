class Auth::Shopping::BarCode
	include Mongoid::Document

	## let me continue with the navigation, 

	field :resource_id, type: String
	field :resource_class, type: String
	field :assigned_to_object_id, type: String
	field :assigned_to_object_class, type: String
	field :bar_code_tag, type: String
	## this is used in the show_action to force render the show view, in case we just want to view the barcode record and not redirect to the 
	attr_accessor :force_show
	attr_accessor :go_to_next_step

	## the primary link of the object to which to redirect.
	## this is se tbefore show.
	attr_accessor :assigned_to_object

	## this changes what is being used as id.

	def to_param
		bar_code_tag
	end

	def self.find(*args)
		@bar_codes = Auth::Shopping::BarCode.where(:bar_code_tag => args[0])
		raise Mongoid::Errors::DocumentNotFound.new(Auth::Shopping::BarCode,[args[0]]) if (@bar_codes.nil? || (@bar_codes.size != 1))
		@bar_codes.first
	end

	## these should be added to any controller that is going to be implementing the bar_code_concern.
	## see auth/shopping/product_controller_concern, for an example of how the permitted params are 	
	def self.allow_params
		[:bar_code_tag,:remove_bar_code]
	end

	
	def self.clear_object(assigned_to_object_id)
		## we just do a find one and update
		begin
			returned_document = where(:assigned_to_object_id => assigned_to_object_id).find_one_and_update(
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
			true
		rescue
			false
		end
		
	end

	## there should not already exist a bar code with this bar code
	## or one where this object id is already assigned.
	def self.upsert_and_assign_object(object)

		returned_document = Auth::Shopping::BarCode.collection.find_one_and_update(
				{
					"$or" => 
					[
						{
							"bar_code_tag" => object.bar_code_tag
						},
						{
							"$and" => 
							[
								{
									"assigned_to_object_id" => object.id.to_s
								},
								{
									"assigned_to_object_class" => object.class.name.to_s
								}
							]
						}
					]
				},
				{
					"$setOnInsert" => {
						"bar_code_tag" => object.bar_code_tag,
						"assigned_to_object_id" => object.id.to_s,
						"assigned_to_object_class" => object.class.name.to_s,
						"resource_id" => object.resource_id,
						"resource_class" => object.resource_class
					}
				},
				{
					:return_document => :after,
					:upsert => true
				})


		return nil if returned_document.nil?

		returned_document = Mongoid::Factory.from_db(Auth::Shopping::BarCode,returned_document)

		return nil if returned_document.assigned_to_object_id.to_s != object.id.to_s

		return nil if returned_document.bar_code_tag != object.bar_code_tag

		return returned_document

	end
	
	## so query options can be added as checkboxes.
	## i can have some by default, others not.	
	def set_assigned_object
		begin
    		self.assigned_to_object = self.assigned_to_object_class.constantize.find(self.assigned_to_object_id)
    	rescue Mongoid::Errors::DocumentNotFound
    		self.errors.add(:_id, "could not find the assigned object")
    	end
	end

end