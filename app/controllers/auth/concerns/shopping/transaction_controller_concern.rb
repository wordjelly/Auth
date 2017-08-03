module Auth::Concerns::Shopping::TransactionControllerConcern

  extend ActiveSupport::Concern

  included do

  end

  ##payment can be made to the transaction
  ##expect to have an amount || cart item, and compulsarily a method
  ##the method will redirect to either gateway payment or cash payment 
  ##or cheque payment
  def pay

  end

  def pay_gateway
  	##will redirect to the payment gateway page.
  end

  def pay_cash
  	##will pop up screen requiring a authorization to accept payment
  end

  def pay_cheque
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

end