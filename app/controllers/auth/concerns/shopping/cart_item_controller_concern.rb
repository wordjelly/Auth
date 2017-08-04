module Auth::Concerns::Shopping::CartItemControllerConcern

  extend ActiveSupport::Concern

  included do
    before_filter :initialize_vars
    before_filter :user_owns_cart_item, :on => [:update,:destroy]
  end

  ##if an id is provided in the permitted params then tries to find that in the database, and makes a new cart item out of it.
  #if no id is provided then creates a new cart_item from the permitted params, but excluding the id key.
  #if a collection i.e plural resources is present in the permitted_params and its also there in our auth resources, then create a resource class and resource symbol out of it and assign user as in the comments.
  def initialize_vars
    @cart_item = permitted_params[:cart_item][:_id] ? self.find(permitted_params[:cart_item][:_id]) : self.new(permitted_params[:cart_item].except(:_id))
    if collection = permitted_params[:resource]
        ##check that the resource exists in the auth_configuration
        if Auth.configuration.auth_resources[collection.singularize.capitalize]
          @resource_class = collection.singularize.capitalize.constantize
          @resource_symbol = collection.singularize.to_sym
          ##check that a user id is provided
          ##check that it is the same as the user_id of the current user or whatever resource.
          ##then assign @user to the current_resource.
          if user_id = permitted_params[:cart_item][:user_id] user_id == self.send("current_#{resource_class.downcase}").id.to_s
            ##so we have set user id, and user as well.
            @user = self.send("current_#{resource_class.downcase}")
          else
            not_found
          end
        else
          not_found 
        end
    else
      not_found
    end
    ##so at the end of all this we have a @user and a @cart_item.
  end

  ##if the cart_item does not match the user id, then it will go to not_found
  def user_owns_cart_item
    @cart_item.user_id == @user.id.to_s or not_found
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
    param.permit({cart_item: [:_id,:product_id,:user_id,:discount_code,:quantity]},:resource)
  end

end
