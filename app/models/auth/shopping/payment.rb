#payment.rb
class Auth::Shopping::Payment
	include Auth::Concerns::Shopping::PaymentConcern
	#embeds_many :cart_item_payment_results
end