module Auth::Concerns::OwnerConcern

	extend ActiveSupport::Concern
	include Auth::Concerns::ChiefModelConcern
	included do 

		## resource id is not essential for the creation of a cart.

		## but if a resource id is present, then a resource class must be provided.

		field :resource_id, type: String
		field :resource_class, type: String
		
		validates_presence_of :resource_class, if: Proc.new{|c| !c.resource_id.nil?}

		## you cannot change the resource_id or owner of the object once it is set.
		validate :resource_id_not_changed



	end


	def get_resource
		self.resource_class.capitalize.constantize.find(self.resource_id)
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
