module Auth::Concerns::Shopping::TransactionControllerConcern

  extend ActiveSupport::Concern

  included do
    ##this ensures api access to this controller.
    include Auth::Concerns::DeviseConcern
    include Auth::Concerns::TokenConcern
    before_filter :do_before_request
    before_filter :initialize_vars

  end

  ##if an id is provided in the permitted params then tries to find that in the database, and makes a new cart item out of it.
  #if no id is provided then creates a new cart_item from the permitted params, but excluding the id key.
  #if a collection i.e plural resources is present in the permitted_params and its also there in our auth resources, then create a resource class and resource symbol out of it and assign resource as in the comments.
  def initialize_vars
    
    @id = permitted_params[:id]
    @name = permitted_params[:transaction][:parent_name]
    @notes = permitted_params[:transaction][:parent_notes]
    @add_cart_item_ids = permitted_params[:transaction][:add_cart_item_ids]
    @remove_cart_item_ids = permitted_params[:transaction][:remove_cart_item_ids]
    if @cart_item_class = Auth.configuration.cart_item_class
      begin
        @cart_item_class = @cart_item_class.constantize
        if @id
          
          @cart_items = @cart_item_class.find_cart_items(@resource,@id)
        end
      rescue => e
        not_found(e.to_s)
      end
    else
      not_found("cart item class not specified in configuration")
    end
  end

  ##override the as_json for cart_item, to show errors if there are any, otherwise just the id.
  def show
    respond_with (@cart_items.compact || []), :template => 'shopping/cart_items/index.json.erb'
  end

  ##responds with an array of the created cart items.
  def create
    #puts "came to create action in concern."
    @id = BSON::ObjectId.new
    @cart_items = add_cart_items(@add_cart_item_ids) if @add_cart_item_ids
    respond_with (@cart_items.compact || []), :template => 'shopping/cart_items/index.json.erb'
  end

  ## always returns an empty array.
  def update
    not_found("please provide a transaction id") unless @id
    added = []
    removed = []
    if @add_cart_item_ids && @cart_items
      added = add_cart_items(@add_cart_item_ids + @cart_items.map{|c| c = c.id.to_s})
    elsif @add_cart_item_ids
      added = add_cart_items(@add_cart_item_ids)
    elsif @cart_items
      added = add_cart_items(@cart_items.map{|c| c = c.id.to_s})
    end
    removed = remove_cart_items(@remove_cart_item_ids) if @remove_cart_item_ids
    #@cart_items = added + removed
    respond_with [], :template => 'shopping/cart_items/index.json.erb'
  end

  ##will respond with nothing, or an array of cart_items that were removed, or whatever errors they have for not remvoing them.
  def destroy    
    @cart_items = remove_cart_items(@cart_items.map{|c| c = c.id.to_s}) if @cart_items
    respond_with (@cart_items.compact || []), :template => 'shopping/cart_items/index.json.erb'
  end

  private
  ##returns array of cart items or array of nulls.
  def add_cart_items(item_ids)
    item_ids.map {|id|
      if cart_item = @cart_item_class.find(id)
        cart_item.parent_id = @id if @id
        cart_item.parent_name = @name if @name
        cart_item.parent_notes = @notes if @notes
        cart_item.resource_id = @resource.id.to_s 
        cart_item.save
        cart_item   
      end
    }
  end

  ##returns array of cart items or array of nulls
  def remove_cart_items(item_ids)
    item_ids.map {|id|
      if cart_item = @cart_item_class.find(id)
        cart_item.parent_id = nil
        cart_item.resource_id = @resource.id.to_s
        cart_item.save
        cart_item
      end
    }
  end

  ##the transaction id must be available here.
  ##as well as the payment transaction id.
  def payment_success_callback
    not_found("we couldn't find that transaction") unless @cart_items
    ##if this is false then we have to ask them to go and verify payment again.
    @resp = @resource.after_payment_success(@cart_items)
    if @resp == true
        Notify.send_notification(@cart_items,@resource,@resp)
    else

    end
    ##and now send a notification to the payment recipient.
  end

  def payment_failure_callback

  end

  def send_payment
    not_found("we couldn't find that transaction") unless @cart_items
    not_found("you are not authorized to make this payment") unless @resource.can_pay(@cart_items)
    not_found("something went wrong, please try again") unless @resource.send_payment(@cart_items)
    ##now forward to whatever payment technique is being used.

  end

  

  def pay
    ################### BEFORE PAY ##################
    not_found unless @cart_items
    before_pay_responses = @cart_items.map{|c| c = c.before_send_payment(BSON::ObjectId.new)}.uniq
    not_found("could not initialize process, please try again") if (before_pay_responses.size > 1 || before_pay_responses[0] == false)
    ################## PAY ##########################
    payment_type = params[:payment_type]
    payment_purpose = params[:payment_purpose]
    not_found("please enter a payment type") unless payment_type
  end
  
  
  def permitted_params
    ##can there be more than one cart_item for the same product_id and resource_id, answer is yes, he can reorder the same product.
    ##so to update , we will have to permit the id, to be sent in.
    params.permit({transaction: [{:add_cart_item_ids => []},{:remove_cart_item_ids => []},:parent_name,:parent_notes]},:id)
  end

end