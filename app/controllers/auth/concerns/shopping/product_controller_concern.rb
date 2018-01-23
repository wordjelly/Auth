module Auth::Concerns::Shopping::ProductControllerConcern

  extend ActiveSupport::Concern

  included do
    
  
  end

  def initialize_vars
  	instantiate_shopping_classes
    @product_params = permitted_params.fetch(:product,{})
    @auth_shopping_product = params[:id] ? @product_class.find_self(params[:id],current_signed_in_resource) : @product_class.new(@product_params)
  end

  

  def create
    check_for_create(@auth_shopping_product)
    @auth_shopping_product = add_owner_and_signed_in_resource(@auth_shopping_product)
  	@auth_shopping_product.save
  	#respond_with @auth_shopping_product
  end

  def update
    check_for_update(@auth_shopping_product)
    @auth_shopping_product = add_owner_and_signed_in_resource(@auth_shopping_product)
    @auth_shopping_product.assign_attributes(@product_params)
    @auth_shopping_product.save
    #respond_with @auth_shopping_product
  end

  def index
    instantiate_shopping_classes
    @auth_shopping_products = @product_class.all
    #respond_with @auth_shopping_products
  end

  def show
    instantiate_shopping_classes
    @auth_shopping_product = @product_class.find(params[:id])
    #respond_with @auth_shopping_product
  end

  def destroy
    check_for_destroy(@auth_shopping_product)
    @auth_shopping_product.delete
  end

  def new
    
    
  end

  def permitted_params
  	params.permit({:product => [:name,:price]})
  end

end