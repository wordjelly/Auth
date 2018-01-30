module PayumoneySupport

	## @param[Auth::Shopping::Payment] payment
	## @return[Hash] a hash of params as expected from payumoney. It doesn't matter if the parameters convey a failure or success. This function just returns a params hash.
	def self.payment_callback_params(payment)

		{"mihpayid"=>"403993715517179378", "mode"=>"CC", "status"=>"failure", "unmappedstatus"=>"failed", "key"=>"gtKFFx", "txnid"=> payment.id.to_s, "amount"=> payment.amount.to_s, "cardCategory"=>"domestic", "discount"=>"0.00", "net_amount_debit"=>"0.00", "addedon"=>"2018-01-29 17:08:40", "productinfo"=>"shopping_cart", "firstname"=>"bhargav", "lastname"=>"", "address1"=>"", "address2"=>"", "city"=>"", "state"=>"", "country"=>"", "zipcode"=>"", "email"=>"bhargav.r.raut@gmail.com", "phone"=>"9561137096", "udf1"=>"", "udf2"=>"", "udf3"=>"", "udf4"=>"", "udf5"=>"", "udf6"=>"", "udf7"=>"", "udf8"=>"", "udf9"=>"", "udf10"=>"", "hash"=>"b3812b0b5aceb7edf4f94dd8237ce939f1bf21e7779e98addcdbee32920e871a50b30eefb78535cfb5e25c3c9eab93b5938670116f02d67e7cd2beccba484468", "field1"=>"180570", "field2"=>"922785", "field3"=>"20180129", "field4"=>"MC", "field5"=>"298836426886", "field6"=>"45", "field7"=>"1", "field8"=>"3DS", "field9"=>" Verification of Secure Hash Failed: E700 -- Unspecified Failure -- Unknown Error -- Unable to be determined--E500", "payment_source"=>"payu", "PG_TYPE"=>"AXISPG", "bank_ref_num"=>"180570", "bankcode"=>"CC", "error"=>"E500", "error_Message"=>"Bank failed to authenticate the customer", "name_on_card"=>"any name", "cardnum"=>"512345XXXXXX2346", "cardhash"=>"This field is no longer supported in postback params.", "issuing_bank"=>"HDFC", "card_type"=>"MAST", "controller"=>"shopping/payments", "action"=>"update", "id"=> payment.id.to_s}.deep_symbolize_keys

	end

end