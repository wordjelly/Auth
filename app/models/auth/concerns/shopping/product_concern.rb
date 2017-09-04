##need a seperate model that implements it
module Auth::Concerns::Shopping::ProductConcern

	extend ActiveSupport::Concern
	include Auth::Concerns::ChiefModelConcern
	included do 
		
		field :price, type: BigDecimal
		field :name, type: String

	end



end