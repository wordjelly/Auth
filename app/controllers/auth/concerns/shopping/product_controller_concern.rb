module Auth::Concerns::Shopping::ProductControllerConcern

  extend ActiveSupport::Concern

  included do
    
    

    
  end

  def initialize_vars
  	instantiate_shopping_classes
    @product_params = permitted_params.fetch(:product,{})
    @product = params[:id] ? @product_class.find_self(params[:id],current_signed_in_resource) : @product_class.new(@product_params)
  end

  def is_admin_user
  	not_found("You don't have sufficient privileges to complete that action") if !current_signed_in_resource.is_admin?
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
    instantiate_shopping_classes
    respond_with @product_class.all
  end

  def show
    instantiate_shopping_classes
    @product = @product_class.find(params[:id])
    respond_with @product
  end

  def destroy
    check_for_destroy(@product)
    @product.delete
  end

  def permitted_params
  	params.permit({:product => [:name,:price]})
  end

end