module Auth::Concerns::Shopping::PayUMoneyControllerConcern

  extend ActiveSupport::Concern


  included do

  	protect_from_forgery :except => [:update]

  end

  ## This includes the params sent back in the payumoney callback + 
  ## PLUS the params that we send to the payumoney endpoint[:amount,:txnid,:surl,:furl,:productinfo,:firstname,:email,:phone]
  ## => of these, [firstname, email, phone, amount and txnid] are also sent back in the payumoney callback.
  ## PLUS the params that are native to the payment concern [:payment_type, :cart_id]
  ## Everywhere txnid, and :id is the same thing.
  def payumoney_params
  	[:payment_type, :amount, :cart_id, :txnid, :surl, :furl, :productinfo, :firstname, :email, :phone,:mihpayid, :mode, :status, :unmappedstatus, :key, :cardCategory, :discount, :net_amount_debit, :addedon, :lastname, :address1, :address2, :city, :state, :country, :zipcode, :udf1, :udf2, :udf3, :udf4, :udf5, :udf6, :udf7, :udf8, :udf9, :udf10, :hash, :field1, :field2, :field3, :field4, :field5, :field6, :field7, :field8, :field9, :payment_source, :PG_TYPE, :bank_ref_num, :bankcode, :error, :error_Message, :name_on_card, :cardnum, :cardhash, :issuing_bank, :card_type ]
  end

  ##note that the payumoney callback makes a POST requet to whatever url you specifiy.
  ##This does not suit our puprose, since we want it to make a PUT request to the update_url.
  ##for this purpose a route has been added to the dummy apps routes file, that maps a POST request to the update path for the 


  ## The issue here was that , in the callback from payumoney all the params are just lying in the params hash.
  ## In order to add them all under a :payment, the params are first duplicated,and then into the :payment key, all those keys are merged from the open hash that are present in the payumoney params defined above.
  ## Thereafter, permit is called on duplicated_params.
  def permitted_params
  	duplicated_params = params.dup
  	payment = duplicated_params["payment"] || {}
  	k = duplicated_params.keep_if{|c| payumoney_params.include? c.to_sym}
  	payment = k.merge(payment)
  	duplicated_params["payment"] = payment
  	duplicated_params.permit({payment: payumoney_params},:id)
  end


  ##this method is overriden here from the payment_concern.
  def gateway_callback(pr)
  	notification = PayuIndia::Notification.new(request.query_string, options = {:key => Auth.configuration.payment_gateway_info[:key], :salt => Auth.configuration.payment_gateway_infp[:salt], :params => pr[:payment]})
  	status = 0
  	status = 1 if(notification.acknowledge && notification.complete?)
  end

end