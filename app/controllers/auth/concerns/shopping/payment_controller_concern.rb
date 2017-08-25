=begin
 ##the transaction id must be available here.
  ##as well as the payment transaction id.
  def payment_success_callback
    not_found("we couldn't find that transaction") unless @cart_items
    ##if this is false then we have to ask them to go and verify payment again.
    @resp = @resource.after_payment_success(@cart_items)
    if @resp == true
        Notify.send_notification(@cart_items,@resource,@resp)
    end
    ###will have to create views for all these actions.
  end

  def payment_failure_callback
    ##will have to create views here as well.
  end

  def send_payment
    not_found("we couldn't find that transaction") unless @cart_items
    not_found("you are not authorized to make this payment") unless @resource.can_pay(@cart_items)
    not_found("something went wrong, please try again") unless @resource.send_payment(@cart_items)
    
  end
=end