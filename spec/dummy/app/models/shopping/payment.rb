class Shopping::Payment
	include Auth::Concerns::Shopping::PaymentConcern
	include Auth::Concerns::Shopping::PayUMoneyConcern
end