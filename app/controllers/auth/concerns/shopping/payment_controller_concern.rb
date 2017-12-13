module Auth::Concerns::Shopping::PaymentControllerConcern

  extend ActiveSupport::Concern

  included do
    

   include Auth::Concerns::DeviseConcern
   include Auth::Concerns::TokenConcern

   before_filter :do_before_request  , :only => [:create,:update,:destroy,:show,:index, :new]
   before_filter :initialize_vars, :only => [:create,:update,:destroy,:show,:index, :new]
    
  end

  def initialize_vars
    @payment_class = Auth.configuration.payment_class.constantize
  end

  def show
    @payment = @payment_class.find(params[:id])
    @payment = add_signed_in_resource(@payment)
    @payment.verify_payment 
  end

  def index

  end

  def new
    @payment = @payment_class.new(permitted_params[:payment])
    @payment = add_signed_in_resource(@payment)
  end

  def create
    @payment = @payment_class.new(permitted_params[:payment])
    @payment.payment_params = params
    @payment.resource_id = lookup_resource.id.to_s
    @payment.resource_class = lookup_resource.class.name
    @payment = add_signed_in_resource(@payment)
    @payment.save
    respond_with @payment
  end

  ##in the normal process of making a cash payment
  ##we render a cash form, then we create a payment and then we should in the show screen,to confirm and commit the payment which finally brings it here.
  ##validations in the create call should look into whether there is a picture/cash/cheque whatever requirements are there.
  def update
    puts "CAME TO UPDATE ACTION."
    @payment = @payment_class.find(params[:id])
    @payment = add_signed_in_resource(@payment)
    @payment.assign_attributes(permitted_params)
    ##note that params and not permitted_params is called, here because the gateway sends back all the params as a naked hash, and that is used directly to verify the authenticity, in the gateway functions.
    @payment.payment_params = params
    @payment.save
    respond_with @payment
  end

  def destroy
    
  end


  def permitted_params
    payment_params = [:payment_type, :amount, :cart_id,:payment_ack_proof, :refund]

    ## payment status is allowed only if the user is an admin user.
    payment_params << :payment_status if (current_signed_in_resource && current_signed_in_resource.is_admin?)

    puts "payment params becomes: #{payment_params.to_s}"

    params.permit({payment: payment_params},:id)
    
  end

end