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
  	[:txnid, :surl, :furl, :productinfo, :firstname, :email, :phone]
  end

  ##note that the payumoney callback makes a POST requet to whatever url you specifiy.
  ##This does not suit our puprose, since we want it to make a PUT request to the update_url.
  ##for this purpose a route has been added to the dummy apps routes file, that maps a POST request to the update path for the 

  ## permits the original parameters defined in the payment_controller_concern and the additional params that are defined here as "payumoney_params, alongwith id."
  def permitted_params
    super.tap do |r|
     r.permit({payment: payumoney_params + r["payment"].keys.map{|c| c = c.to_sym}},:id)
    end
  end

 

end