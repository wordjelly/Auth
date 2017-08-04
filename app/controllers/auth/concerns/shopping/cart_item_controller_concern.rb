module Auth::Concerns::Shopping::CartItemControllerConcern

  extend ActiveSupport::Concern

  included do
    before_filter :initialize_vars
    before_filter :user_owns_cart_item, :on => [:update,:destroy,:show]
  end

  ##if an id is provided in the permitted params then tries to find that in the database, and makes a new cart item out of it.
  #if no id is provided then creates a new cart_item from the permitted params, but excluding the id key.
  #if a collection i.e plural resources is present in the permitted_params and its also there in our auth resources, then create a resource class and resource symbol out of it and assign user as in the comments.
  def initialize_vars
    @cart_item = permitted_params[:id] ? self.find(permitted_params[:id]) : self.new(permitted_params[:cart_item])
    collection = permitted_params[:resource] or not_found
    Auth.configuration.auth_resources[collection.singularize.capitalize] or not_found
    @resource_class = collection.singularize.capitalize.constantize
    @resource_symbol = collection.singularize.to_sym
    @user = self.send("current_#{resource_class.downcase}")
    user_owns_cart_item? or not_found
  end

  ##if the cart_item does not match the user id, then it will go to not_found
  def user_owns_cart_item?
    ##this can be overriden to give administrators the ability to see the resource/update/modify whatever.
    if user_id = permitted_params[:cart_item][:user_id] && @user 
      ##check if this is the same as the currently signed in user.
      return user_id == @user.id.to_s
    end
    false
  end


  ##expects the product id, user_id is the logged in user, and quantity 
  def create
    ##ensure that the cart item is new
    @cart_item.new_record? or not_found
    @cart_item.user_id = @user.id.to_s
    @cart_item.save!
    respond_with @cart_item
  end

  ##only permits the quantity to be changed, transaction id is internally assigned and can never be changed by the external world.
  def update
    !@cart_item.new_record? or not_found
    @cart_item.quantity = permitted_params[:cart_item][:quantity] || @cart_item.quantity
    @cart_item.discount_code = permitted_params[:cart_item][:quantity] || @cart_item.discount_code
    @cart_item.save!
    respond_with @cart_item
  end

  def show
    respond_with @cart_item
  end

  ##we will have a cart item that is new and useless, and a user.
  ##so we just need a query to show all the cart items of this user
  def index
    @cart_items = self.where(:user_id => @user.id.to_s)
  end


  ##can be removed.
  def destroy
    resp = @cart_item.destroy
    respond_to do |format|

    end
  end

  def permitted_params
    ##can there be more than one cart_item for the same product_id and user_id, answer is yes, he can reorder the same product.
    ##so to update , we will have to permit the id, to be sent in.
    params.require(:cart_item)
    params.require(:resource)
    param.permit({cart_item: [:product_id,:user_id,:discount_code,:quantity]},:resource,:id)
  end

end
