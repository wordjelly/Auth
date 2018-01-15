module Auth::Concerns::Shopping::CartControllerConcern

  extend ActiveSupport::Concern

  included do
    ##this ensures api access to this controller.
    include Auth::Concerns::DeviseConcern
    include Auth::Concerns::TokenConcern
    before_filter :do_before_request 
    before_filter :initialize_vars
    before_filter :is_admin_user , :only => [:create,:update,:destroy]
  end

  def initialize_vars
  	instantiate_shopping_classes
    @cart_params = permitted_params.fetch(:product,{})
    @cart = params[:id] ? @product_class.find_product(params[:id],current_signed_in_resource) : @product_class.new(@product_params)
  end

  def is_admin_user
  	not_found("You don't have sufficient privileges to complete that action") if !current_signed_in_user.is_admin?
  end

  def create
    check_for_create(@product)
    @product = add_owner_and_signed_in_resource(@product)
  	@product.save
  	respond_with @product
  end

  def update
    check_for_update(@product)
    @product = add_owner_and_signed_in_resource(@product)
    @product.assign_attributes(@product_params)
    @product.save
    respond_with @product
  end

  def index
    @product_class.all
  end

  def show

  end

  def destroy
    check_for_destroy(@product)
    @product.delete
  end

  def permitted_params
  	params.permit({:product => {:name,:price}})
  end

end