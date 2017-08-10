##need a seperate model that implements it
module Auth::Concerns::Shopping::ProductConcern

	extend ActiveSupport::Concern
	
	

	included do 
		
		field :price, type: BigDecimal
		field :name, type: String

	end

end