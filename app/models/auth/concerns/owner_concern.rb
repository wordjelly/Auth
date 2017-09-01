module Auth::Concerns::OwnerConcern

	extend ActiveSupport::Concern
	include Auth::Concerns::ChiefModelConcern
	included do 

		field :resource_id, type: String
		validate :resource_id_not_changed

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
