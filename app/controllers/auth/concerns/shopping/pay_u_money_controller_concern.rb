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
  	[:payment_type, :amount, :cart_id, :txnid, :surl, :furl, :productinfo, :firstname, :email, :phone]
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


 

end