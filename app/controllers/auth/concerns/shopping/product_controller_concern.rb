module Auth::Concerns::Shopping::ProductControllerConcern

  extend ActiveSupport::Concern

  included do
    
    include Auth::Shopping::Products::ProductsHelper

  end

  def initialize_vars
  	instantiate_shopping_classes
    @auth_shopping_product_params = permitted_params.fetch(:product,{})
    @auth_shopping_product = params[:id] ? @auth_shopping_product_class.find_self(params[:id],current_signed_in_resource) : @auth_shopping_product_class.new(@auth_shopping_product_params)
  end

  

  def create
    check_for_create(@auth_shopping_product)
    @auth_shopping_product = add_owner_and_signed_in_resource(@auth_shopping_product,{:owner_is_current_resource => true})
  	
    @auth_shopping_product.save
    respond_with @auth_shopping_product
    
  end

  def update
    check_for_update(@auth_shopping_product)
    @auth_shopping_product = add_owner_and_signed_in_resource(@auth_shopping_product,{:owner_is_current_resource => true})
    @auth_shopping_product.assign_attributes(@auth_shopping_product_params)
    @auth_shopping_product.save
    respond_with @auth_shopping_product
    
  end

  def index
    instantiate_shopping_classes
    @auth_shopping_products = @auth_shopping_product_class.all
  end

  def show
    instantiate_shopping_classes
    @auth_shopping_product = @auth_shopping_product_class.find(params[:id])
  end

  def destroy
    check_for_destroy(@auth_shopping_product)
    @auth_shopping_product.delete
    respond_with @auth_shopping_product
  end

  def new
    
  end

  def edit

  end

  def permitted_params
  	params.permit({:product => [:name,:price]})
  end

end

## how to handle situation where the resource_id and resource_class is 