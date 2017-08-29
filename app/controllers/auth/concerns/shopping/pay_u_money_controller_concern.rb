module Auth::Concerns::Shopping::PayUMoneyControllerConcern

  extend ActiveSupport::Concern

  included do
    
  end

  def permitted_params
  	params.permit({payment: [:payment_type, :amount, :cart_id, :txnid, :surl, :furl, :productinfo, :firstname, :email, :phone ]},:id)
  end

end