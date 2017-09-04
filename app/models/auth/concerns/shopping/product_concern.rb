##need a seperate model that implements it
module Auth::Concerns::Shopping::ProductConcern

	extend ActiveSupport::Concern
	include Auth::Concerns::ChiefModelConcern
	included do 
		
		field :price, type: BigDecimal
		field :name, type: String

		validates_presence_of :payable_at
		validates_presence_of :cancellable_at

	end



end