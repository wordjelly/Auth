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
  end

  def create

  end

  def update

  end

  def destroy

  end

  def permitted_params
    params.permit({payment: [:payment_type, :amount, :cart_id]},:id)
  end

end