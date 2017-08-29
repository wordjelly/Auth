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
    puts "came to create with params:"
    puts params.to_s
    @payment = @payment_class.new(permitted_params[:payment])
    @payment.save
    puts "payment after save:"
    puts @payment.attributes.to_s
    respond_with @payment
  end

  def update

  end

  def destroy

  end

  ##method should be overridden, to include whatever params the payment gateway needs.
  ##this method has been overriden in the dummy app for the moment.
  def permitted_params
    params.permit({payment: [:payment_type, :amount, :cart_id]},:id)
  end

end