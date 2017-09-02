##need a seperate model that implements it
module Auth::Concerns::Shopping::ProductConcern

	extend ActiveSupport::Concern
	include Auth::Concerns::ChiefModelConcern
	included do 
		
		field :price, type: BigDecimal
		field :name, type: String

		###################### product status fields ##################
		## one of the stages mentioned below.
		field :stage, type: String


		## payable when  : the latest stage at which this product is payable.?
		## this is also one of the stages mentioned below
		field :payable_at, type: String


		## cancellable when ?
		## the latest stage at which this product is cancellable.
		## also one of the stages mentioned below
		field :cancellable_at, type: String

		## how much longer till it reaches the end stage?
		## for this you have to depend on setting an end stage.
		field :expected_time_of_arrival, type: Integer

		validates_presence_of :payable_at
		validates_presence_of :cancellable_at

	end

	module ClassMethods

		def stages
			{
				"AWAITING_PAYMENT" => 0,
				"ORDER_WAITING_TO_BE_ACCEPTED" => 1,
				"ACCEPTED_FOR_PROCESSING" => 2,
				"PROCESSING" => 3,
				"PROCESSING_COMPLETED" => 4,
				"DISPATCHED" => 5
			}
		end

	end


end