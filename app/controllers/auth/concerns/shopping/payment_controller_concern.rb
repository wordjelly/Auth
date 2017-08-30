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
    @payment = @payment_class.find(params[:id])
    respond_with @payment
  end

  def index

  end

  def new
    @payment = @payment_class.new(permitted_params[:payment])
  end

  def create
    @payment = @payment_class.new(permitted_params[:payment])
    @payment.save
    respond_with @payment
  end

  ##in the normal process of making a cash payment
  ##we render a cash form, then we create a payment and then we should in the show screen,to confirm and commit the payment which finally brings it here.
  ##validations in the create call should look into whether there is a picture/cash/cheque whatever requirements are there.
  def update
    pr = permitted_params.deep_symbolize_keys 
    @id = pr[:payment][:id] || pr[:payment][:txnid]
    puts "the permitted params are:" 
    puts permitted_params.to_s
    @payment = @payment_class.find(@id)
    @payment.gateway_callback(pr) if @payment.is_gateway?
    #@payment.cash_callback(pr) if @payment.is_cash?
    #@payment.cheque_callback(pr) if @payment.is_cheque?
    #@payment.card_callback(pr) if @payment.is_card?
    @payment.save
  end

  def destroy
    
  end

  ##method should be overridden, to include whatever params the payment gateway needs.
  ##this method has been overriden in the dummy app for the moment.
  def permitted_params
    params.permit({payment: [:payment_type, :amount, :cart_id]},:id)
  end

end