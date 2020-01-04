module Auth::Concerns::Shopping::CartItemControllerConcern

  extend ActiveSupport::Concern

  included do
      
    ## to be able to initialize a cart item from a product
    ## inside the create_multiple def.
    include Auth::Shopping::Products::ProductsHelper
    include Auth::Shopping::CartItems::CartItemsHelper

  end

  

  ##if an id is provided in the permitted params then tries to find that in the database, and makes a new cart item out of it.
  #if no id is provided then creates a new cart_item from the permitted params, but excluding the id key.
  #if a collection i.e plural resources is present in the permitted_params and its also there in our auth resources, then create a resource class and resource symbol out of it and assign resource as in the comments.
  def initialize_vars
    instantiate_shopping_classes

    @auth_shopping_discount_object_params = permitted_params.fetch(:discount,{})

    
    if !@auth_shopping_discount_object_params.blank?

    @auth_shopping_discount = params[:id] ? @auth_shopping_discount_class.find(params[:id]) : @auth_shopping_discount_class.new(@auth_shopping_discount_object_params)
    
    end

    @auth_shopping_cart_item_params = permitted_params.fetch(:cart_item,{})
    @auth_shopping_cart_item = params[:id] ? @auth_shopping_cart_item_class.find_self(params[:id],current_signed_in_resource) : @auth_shopping_cart_item_class.new(@auth_shopping_cart_item_params)
    
  end


  ##expects the product id, resource_id is the logged in resource, and quantity 
  def create
    check_for_create(@auth_shopping_cart_item)
    @auth_shopping_cart_item = add_owner_and_signed_in_resource(@auth_shopping_cart_item)
    @auth_shopping_cart_item = @auth_shopping_cart_item.create_with_embedded(@auth_shopping_cart_item.product_id)
    puts "auth shopping cart item becomes:"
    puts @auth_shopping_cart_item.to_s
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
    puts "the accepted is:"
    puts @auth_shopping_cart_item.accepted.to_s
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
  
  def create_many_items
    cart_items = []
    errors = []
    params[:cart_item][:product_ids].each do |product_id|
      cart_item = Auth.configuration.cart_item_class.constantize.new(product_id: product_id)
      cart_item.resource_id = lookup_resource.id.to_s
      cart_item.resource_class = lookup_resource.class.name.to_s
      cart_item.signed_in_resource = current_signed_in_resource
      create_result = cart_item.create_with_embedded(cart_item.product_id)
      if create_result == false
        ## here there will be the validation errors on the original instance.
        cart_items << cart_item
        errors << cart_item.errors.full_messages
      else
        ## here the create_result becomes the new cart_item.
        cart_items << create_result
      end
    end
    respond_to do |format|
      format.html do 
        redirect_to cart_items_path
      end
      format.json do 
        if errors.empty?
          render :json => {cart_items: cart_items}, :status => 200
        else
          render :json => {cart_items: cart_items, errors: errors}, :status => 422
        end
      end
    end
  end


  def create_multiple
    #puts "came to create multiple."
    #puts "params are:"
    #puts params.to_s
    @auth_shopping_cart_items = []
    @auth_shopping_cart = @auth_shopping_cart_class.new(:add_cart_item_ids => [], :remove_cart_item_ids => [])
    #puts "auth shopping discount is:"
    #puts @auth_shopping_discount.to_s
    @auth_shopping_cart.discount_id = @auth_shopping_discount.id.to_s
   
    unless @auth_shopping_discount.new_record?
      errors = []
      @auth_shopping_discount.product_ids.each do |product_id|

          cart_item = Auth.configuration.cart_item_class.constantize.new 
          cart_item = add_owner_and_signed_in_resource(cart_item)  
          if cart_item_created = cart_item.create_with_embedded(product_id)
            @auth_shopping_cart_items << cart_item_created
            @auth_shopping_cart.add_cart_item_ids << cart_item_created.id.to_s
          else
            @auth_shopping_cart_items << cart_item
            errors << cart_item.errors.full_messages
          end 
      end
    else

    end
      
    respond_to do |format|
      format.html do 
        render 'create_multiple.html.erb'
      end

      format.json do 
        unless errors.empty?
          render :json => {cart_items: @auth_shopping_cart_items, errors: errors}, :status => 422
        else
          render :json => {cart_items: @auth_shopping_cart_items}, :status => 200
        end
      end

    end
     

  end

  ## this permitted params is overridden in the dummy app, and as a result throws unpermitted parameters for the daughter app parameters, even though they are subsequently permitted, since super is called first.
  def permitted_params

    
    if action_name.to_s == "update"
      
      params.permit({cart_item: [:discount_code,:quantity]},:id)

    elsif action_name.to_s == "create_multiple"
      params.permit({discount: [:id, {:product_ids => []}]})
    elsif action_name.to_s == "create_many_items"
      params.permit({:cart_item => [:product_ids]})
    else

      params.permit({cart_item: [:product_id,:discount_code,:quantity]},:id)

    end


  end

end
