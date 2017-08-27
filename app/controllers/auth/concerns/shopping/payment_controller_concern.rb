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
module Auth::Concerns::Shopping::PaymentControllerConcern

  extend ActiveSupport::Concern

  included do
    ##this ensures api access to this controller.
    include Auth::Concerns::DeviseConcern
    include Auth::Concerns::TokenConcern
    before_filter :do_before_request
    before_filter :initialize_vars
  end

  def initialize_vars
    @payment_class = Auth.configuration.payment_class.constantize
  end

  def show

  end

  def index

  end

  def new
    @payment = @payment_class.new(permitted_params[:payment])
    ##so from here basically the payment form will have to be rendered depending upon the payment type.
    ##if it is cash/cheque, then a picture of the signature.
    ##if it is cheque then the cheque number
    ##if it is gateway then the email/phone/first-name/last-name
    ##after this it should go to create, where it should get saved and then redirected from there to either the success url or to the gateway url.
  end

  def create

  end

  def update

  end

  def destroy

  end

  def permitted_params
    params.permit({payment: [:transaction_id, :payment_type, :amount]},:id)
  end

end