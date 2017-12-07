module Auth::Concerns::OwnerConcern

	extend ActiveSupport::Concern
	include Auth::Concerns::ChiefModelConcern
	included do 

		## resource id is not essential for the creation of a cart.

		## but if a resource id is present, then a resource class must be provided.

		field :resource_id, type: String
		field :resource_class, type: String

		## THERE ARE BASICALLY THREE KINDS OF USERS THAT WE MAY NEED.

		## ONE : The resource that is considered as the owner of the object . this uses the resource_id and resource_class. It is got by calling get_resource on the object.

		attr_accessor :owner_resource

		## SIGNED_IN_RESOURCE : the resource that is currently signed in, and should be assigned to this model instance, in the controller. This is can be got by calling the method currently_signed_in_resource on the token_controller_concern.

		attr_accessor :signed_in_resource



		validates_presence_of :resource_class, if: Proc.new{|c| !c.resource_id.nil?}

		## you cannot change the resource_id or owner of the object once it is set.
		validate :resource_id_not_changed

	end

	## returns the resource that was associated with the object when the object was created.
	## it basically uses the resource_id and resource_class that were saved, when creating the resource.
	## since resources can be created without the resource_class and resource_id being provided, it may return nil if these two are not present.
	def get_resource
		return unless (self.resource_class && self.resource_id) 
		unless owner_resource
			owner_resource = self.resource_class.capitalize.constantize.find(self.resource_id)
		end
		owner_resource
	end


	private

	def resource_id_not_changed
	  ##this method will give you access to be able to reset the resource_id in case the admin is modifying the resource.
	  ##need to check if that can be done?

	  if resource_id_changed? && resource_id_was
	      errors.add(:resource_id, "You cannot change or view this cart item")
	  end
	end

end
