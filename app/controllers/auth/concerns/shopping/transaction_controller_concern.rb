module Auth::Concerns::Shopping::TransactionControllerConcern

  extend ActiveSupport::Concern

  included do

  end

  def gateway_pay_success_callback
    ##will be called if the payment gateway payment succeeds.
    ##and then it should also add a couple of fields, that do stuff like balanace.
    ##
  end

  def gateway_pay_failure_callback
    ##will be called if the payment gateway payment fails for any reason.
  end

  def pay_by_gateway
  	##will redirect to the payment gateway page.
  end

  def pay_by_cash
  	##will pop up screen requiring a authorization to accept payment
  end

  def pay_by_cheque
  	##will pop up screen requiring a authorizatino to accept payment.
  end

  def refund
  	##same as above.
  end

  def refund_gateway

  end

  def refund_cash

  end

  def refund_cheque

  end

  ##get id.
  def show

  end

  ##cart id instance
  def add_cart_item

  end

  ##cart id id number
  def remove_cart_item

  end

  ##transaction object.
  def create

  end

  ##transaction object.
  def update

  end

  ##transaction object id.
  def destroy

  end

  def permitted_params
    ##can there be more than one cart_item for the same product_id and resource_id, answer is yes, he can reorder the same product.
    ##so to update , we will have to permit the id, to be sent in.
    params.permit({transaction: [:add_cart_item_ids,:remove_cart_item_ids,:preferred_payment_stage,:transaction_status]},:id)
  end

end