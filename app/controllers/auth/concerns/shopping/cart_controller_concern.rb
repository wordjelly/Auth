module Auth::Concerns::Shopping::CartControllerConcern

  extend ActiveSupport::Concern

  included do
    
  end

  ##if an id is provided in the permitted params then tries to find that in the database, and makes a new cart item out of it.
  #if no id is provided then creates a new cart_item from the permitted params, but excluding the id key.
  #if a collection i.e plural resources is present in the permitted_params and its also there in our auth resources, then create a resource class and resource symbol out of it and assign resource as in the comments.
  def initialize_vars
    instantiate_shopping_classes
    @cart_params = permitted_params.fetch(:cart,{})
    @cart = params[:id] ? @cart_class.find_self(params[:id],current_signed_in_resource) : @cart_class.new(@cart_params)
        
  end

  ##override the as_json for cart_item, to show errors if there are any, otherwise just the id.
  def show
    not_found if @cart.nil?
    @cart.prepare_cart
    @cart_items = @cart.cart_items
    respond_with @cart
  end

  ##responds with an array of the created cart items.
  ##resource id is set only during create, never during update.
  def create
    check_for_create(@cart)
    @cart = add_owner_and_signed_in_resource(@cart)
    @cart.save
    respond_with @cart
  end

  ## always returns an empty array.
  def update
    check_for_update(@cart)
    @cart.assign_attributes(@cart_params)
    @cart = add_owner_and_signed_in_resource(@cart)
    @cart.save
    @cart.prepare_cart
    respond_with @cart
  end

  ##will respond with nothing, or an array of cart_items that were removed, or whatever errors they have for not remvoing them.
  def destroy    
    check_for_destroy(@cart)
    @cart.prepare_cart
    @cart.destroy
    respond_with @cart
  end

  ## returns all the carts of the user.
  ## basically all his orders.
  def index
    @carts = @cart_class.where(:resource_id => lookup_resource.id.to_s)
    respond_with @carts
  end

  private

  
 
  ##override this def in your controller, and add attributes to transaction:[], each of the attributes in the transaction key will be cycled through, and if those fields exist on the cart_item, then they will be set.
  def permitted_params
    params.permit({cart: [:name, :notes, {:add_cart_item_ids => []},{:remove_cart_item_ids => []}]},:id)
  end

end