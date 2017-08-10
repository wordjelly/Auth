module Auth::Concerns::Shopping::TransactionControllerConcern

  extend ActiveSupport::Concern

  included do
    ##this ensures api access to this controller.
    include Auth::Concerns::TokenConcern
    before_filter :initialize_vars
  end

  ##if an id is provided in the permitted params then tries to find that in the database, and makes a new cart item out of it.
  #if no id is provided then creates a new cart_item from the permitted params, but excluding the id key.
  #if a collection i.e plural resources is present in the permitted_params and its also there in our auth resources, then create a resource class and resource symbol out of it and assign resource as in the comments.
  def initialize_vars
    if @cart_item_class = Auth.configuration.cart_item_class
      begin
        @cart_item_class = @cart_item_class.constantize
        if permitted_params[:id]
          @cart_items = @cart_item_class.where(:parent_id => permitted_params[:id])
        end
      rescue
        not_found("error instatiating class from cart item class")
      end
    else
      not_found("cart item class not specified in configuration")
    end
  end

  ##override the as_json for cart_item, to show errors if there are any, otherwise just the id.

  def show
    respond_with @cart_items
  end

  
  def create
    t_id = BSON::ObjectId.new
    @cart_items = add_cart_items(t_id)
    respond_with @cart_items
  end

  
  def update
    added_cart_items = add_cart_items(permitted_params[:id])
    removed_cart_items = remove_cart_items
    @cart_items = added_cart_items + removed_cart_items
    respond_with @cart_items
  end

  
  def destroy    
    @cart_items = remove_cart_items(@cart_items)
    respond_with @cart_items
  end

  private
  def add_cart_items(t_id)
    permitted_params[:transaction][:add_cart_item_ids].map {|id|
      if cart_item = @cart_item_class.find(id)
        cart_item.parent_id = t_id
        cart_item.save!
        cart_item   
      end
    }
  end

  ##cart id id number
  def remove_cart_items(remove_cart_item_ids = permitted_params[:transaction][:remove_cart_item_ids])
    remove_cart_item_ids.map {|id|
      if cart_item = @cart_item_class.find(id)
        cart_item.parent_id = nil
        cart_item.save!
        cart_item
      end
    }
  end

  def permitted_params
    ##can there be more than one cart_item for the same product_id and resource_id, answer is yes, he can reorder the same product.
    ##so to update , we will have to permit the id, to be sent in.
    params.permit({transaction: [:add_cart_item_ids,:remove_cart_item_ids]},:id)
  end

end