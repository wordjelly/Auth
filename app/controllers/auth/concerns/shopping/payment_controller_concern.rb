module Auth::Concerns::Shopping::PaymentControllerConcern

  extend ActiveSupport::Concern

  included do
    include Auth::Shopping::Payments::PaymentsHelper
  end

  def initialize_vars
   
    instantiate_shopping_classes
    @auth_shopping_payment_params = permitted_params.fetch(:payment,{})
   
    @auth_shopping_payment = params[:id] ? @auth_shopping_payment_class.find_self(params[:id],current_signed_in_resource) : @auth_shopping_payment_class.new(@auth_shopping_payment_params)
  end

  def show
    @auth_shopping_payment = add_signed_in_resource(@auth_shopping_payment)
    @auth_shopping_payment.set_payment_receipt
    respond_with @auth_shopping_payment
  end

  def index
    ## need to find all the payments
    @auth_shopping_payments = @auth_shopping_payment_class.where(:resource_id => lookup_resource.id.to_s)
    respond_with @auth_shopping_payments
  end

  def new
    @auth_shopping_payment = add_owner_and_signed_in_resource(@auth_shopping_payment)
  end

  def edit

  end

  def create
   
    check_for_create(@auth_shopping_payment)
   
    @auth_shopping_payment.payment_params = params
    
    @auth_shopping_payment = add_owner_and_signed_in_resource(@auth_shopping_payment)
   
    @auth_shopping_payment.save
    respond_with @auth_shopping_payment
  end

  ##in the normal process of making a cash payment
  ##we render a cash form, then we create a payment and then we should in the show screen,to confirm and commit the payment which finally brings it here.
  ##validations in the create call should look into whether there is a picture/cash/cheque whatever requirements are there.
  def update
    #puts "params coming to update are:"
    #puts params.to_s
    check_for_update(@auth_shopping_payment)
    @auth_shopping_payment.assign_attributes(permitted_params[:payment])
    #puts "assigned attrs"
    @auth_shopping_payment = add_owner_and_signed_in_resource(@auth_shopping_payment)
    #puts "added owner"
    ##note that params and not permitted_params is called, here because the gateway sends back all the params as a naked hash, and that is used directly to verify the authenticity, in the gateway functions.
    #puts "these are the attributes assigned in the update action."
    #puts @auth_shopping_payment.attributes.to_s
    @auth_shopping_payment.payment_params = params
    #puts "assigned params."
    save_response = @auth_shopping_payment.save
    
    ## if save successfull then otherwise, respond_with edit.
    respond_with @auth_shopping_payment, location: (save_response == true ? payment_path(@auth_shopping_payment) : edit_payment_path(@auth_shopping_payment))
  
  end

  def destroy
     @auth_shopping_payment = add_signed_in_resource(@auth_shopping_payment)
     if @auth_shopping_payment.signed_in_resource.is_admin?
        @auth_shopping_payment.delete
     end
     respond_with @auth_shopping_payment
  end


  def permitted_params
    payment_params = [:payment_type, :amount, :cart_id,:payment_ack_proof, :refund, :payment_status, :is_verify_payment]

    if !current_signed_in_resource.is_admin?
      payment_params.delete(:payment_status)
      if action_name.to_s == "update"
        payment_params = [:is_verify_payment]
      end
    end
    params.permit({payment: payment_params},:id)
    
  end

end