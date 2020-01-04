class Auth::Shopping::CartItemPaymentResult
	include Auth::Concerns::ChiefModelConcern
	field :cart_item_ids, type: Array, default: []
	field :results, type: Array, default: []
	field :time, type: Integer
	#embedded_in :payment
end