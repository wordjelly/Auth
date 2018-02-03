module Auth::Concerns::Shopping::CartItemControllerConcern

  extend ActiveSupport::Concern

  included do
    
    
  end

  

  ##if an id is provided in the permitted params then tries to find that in the database, and makes a new cart item out of it.
  #if no id is provided then creates a new cart_item from the permitted params, but excluding the id key.
  #if a collection i.e plural resources is present in the permitted_params and its also there in our auth resources, then create a resource class and resource symbol out of it and assign resource as in the comments.
  def initialize_vars
    instantiate_shopping_classes

    @auth_shopping_discount_object_params = permitted_params.fetch(:discount_object,{})
    
    @auth_shopping_discount = @auth_shopping_discount_object_params[:id] ? @auth_shopping_discount_class.find_self(@auth_shopping_discount_object_params[:id],current_signed_in_resource) : @auth_shopping_discount_class.new(@auth_shopping_discount_object_params)

    @auth_shopping_cart_item_params = permitted_params.fetch(:cart_item,{})
    @auth_shopping_cart_item = params[:id] ? @auth_shopping_cart_item_class.find_self(params[:id],current_signed_in_resource) : @auth_shopping_cart_item_class.new(@auth_shopping_cart_item_params)
    
  end


  ##expects the product id, resource_id is the logged in resource, and quantity 
  def create
    ##ensure that the cart item is new
   
    check_for_create(@auth_shopping_cart_item)
    @auth_shopping_cart_item = add_owner_and_signed_in_resource(@auth_shopping_cart_item)
     
    @auth_shopping_cart_item.save

    respond_with @auth_shopping_cart_item
  end

  ##only permits the quantity to be changed, transaction id is internally assigned and can never be changed by the external world.
  def update
    check_for_update(@auth_shopping_cart_item)
    @auth_shopping_cart_item.assign_attributes(@auth_shopping_cart_item_params)
    @auth_shopping_cart_item = add_owner_and_signed_in_resource(@auth_shopping_cart_item)  
    @auth_shopping_cart_item.save
    respond_with @auth_shopping_cart_item
  end

  def show
    not_found if @auth_shopping_cart_item.nil?
    respond_with @auth_shopping_cart_item 
  end

  ##should show those cart items which do not have a parent_id.
  ##since these are the pending cart items.
  ##all remaining cart items have already been assigned to carts
  def index
    @auth_shopping_cart_items = @auth_shopping_cart_item_class.find_cart_items({:resource => lookup_resource}).page 1
    respond_with @auth_shopping_cart_items
  end


  ##can be removed.
  ##responds with 204, and empty response body, if all is ok.
  def destroy
    not_found if @auth_shopping_cart_item.nil?
    @auth_shopping_cart_item.destroy
    respond_with @auth_shopping_cart_item
  end

  ############################################################
  ##
  ##
  ## BULK ITEM CREATE.
  ## This is utilized to create multiple cart items, first , 
  ## then redirects to create a cart, with those cart items.
  ##
  ##
  ############################################################
  def create_multiple
    @auth_shopping_cart_items = []
    @auth_shopping_cart = @auth_shopping_cart_class.new
    unless @auth_shopping_discount.new_record?
      @auth_shopping_discount.product_ids.each do |product_id|
        begin
        if product = @auth_shopping_product_class.find(product_id)
          cart_item = @auth_shopping_cart_item_class.new(product.attributes.except(:_id).merge({:product_id => product_id}))
          cart_item.save
          @auth_shopping_cart_items << cart_item
        end
        rescue => e
          puts "didnt find product id: #{product_id}"
        end
      end
    end
    respond_with @auth_shopping_cart_items, location: "create_multiple.html.erb"
  end

  ## this permitted params is overridden in the dummy app, and as a result throws unpermitted parameters for the daughter app parameters, even though they are subsequently permitted, since super is called first.
  def permitted_params

    
    if action_name.to_s == "update" && !current_signed_in_resource.is_admin?

      
      params.permit({cart_item: [:discount_code,:quantity]},:id)

    elsif action_name.to_s == "create_multiple"
      params.permit({discount_object: [:id, {:product_ids => []}]})
    else

      params.permit({cart_item: [:product_id,:discount_code,:quantity]},:id)

    end


  end

end
