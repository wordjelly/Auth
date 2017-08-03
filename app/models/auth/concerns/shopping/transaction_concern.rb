##need a seperate model that implements it.
module Auth::Concerns::Shopping::TransactionConcern

	extend ActiveSupport::Concern

	include Mongoid::TimeStamps

	included do 
		##the cart items added to this transaction.
		field :cart_item_ids
		##when the person wants to pay
		field :payment_stage
		##all the payments made into and out of this transaction.
		field :payment_history
	end



end