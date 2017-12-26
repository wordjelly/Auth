module Auth::Concerns::Shopping::CartControllerConcern

  extend ActiveSupport::Concern

  included do
    ##this ensures api access to this controller.
    include Auth::Concerns::DeviseConcern
    include Auth::Concerns::TokenConcern
    before_filter :do_before_request  , :only => [:create,:update,:destroy,:show,:index]
    before_filter :initialize_vars, :only => [:create,:update,:destroy,:show,:index]
  end

  ##if an id is provided in the permitted params then tries to find that in the database, and makes a new cart item out of it.
  #if no id is provided then creates a new cart_item from the permitted params, but excluding the id key.
  #if a collection i.e plural resources is present in the permitted_params and its also there in our auth resources, then create a resource class and resource symbol out of it and assign resource as in the comments.
  def initialize_vars
    @cart_class = Auth.configuration.cart_class.constantize
    @cart_params = permitted_params.fetch(:cart,{})
    begin
      @cart = permitted_params[:id] ? @cart_class.find(permitted_params[:id]) : @cart_class.new
    rescue => e
      not_found(e.to_s)
    end
    @add_cart_item_ids = @cart_params[:add_cart_item_ids]
    @remove_cart_item_ids = @cart_params[:remove_cart_item_ids]
    
    @cart_item_class = Auth.configuration.cart_item_class.constantize
  end

  ##override the as_json for cart_item, to show errors if there are any, otherwise just the id.
  def show
    @cart.prepare_cart
    @cart_items = @cart.cart_items
    respond_with @cart
  end

  ##responds with an array of the created cart items.
  ##resource id is set only during create, never during update.
  def create
    not_found("this cart already exists") unless @cart.new_record?
    @cart = @cart_class.new(@cart_params.except(:add_cart_item_ids, :remove_cart_item_ids))
    @cart.resource_id = lookup_resource.id.to_s
    @cart.resource_class = lookup_resource.class.name
    @cart = add_signed_in_resource(@cart)
    @cart.add_or_remove(@add_cart_item_ids,1) if @add_cart_item_ids
    @cart.save
    respond_with @cart
  end

  ## always returns an empty array.
  def update
    not_found("please provide a cart id") if @cart.new_record?
    @cart.assign_attributes(@cart_params.except(:add_cart_item_ids, :remove_cart_item_ids))
    @cart = add_signed_in_resource(@cart)
    puts "the add cart item ids are:"
    puts "#{@add_cart_item_ids}"
    @cart.add_or_remove(@add_cart_item_ids,1) if @add_cart_item_ids
    @cart.add_or_remove(@remove_cart_item_ids,-1) if @remove_cart_item_ids
    @cart.save
    puts "result of save:"
    puts @cart.errors.full_messages.to_s
    @cart.prepare_cart
    puts @cart.get_cart_items
    respond_with @cart
  end

  ##will respond with nothing, or an array of cart_items that were removed, or whatever errors they have for not remvoing them.
  def destroy    
    not_found("please provide a cart id") if @cart.new_record?
    @cart.prepare_cart
    @cart.destroy
    respond_with @cart
  end

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