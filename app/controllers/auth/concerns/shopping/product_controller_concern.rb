module Auth::Concerns::Shopping::CartControllerConcern

  extend ActiveSupport::Concern

  included do
    ##this ensures api access to this controller.
    include Auth::Concerns::DeviseConcern
    include Auth::Concerns::TokenConcern
    before_filter :do_before_request 
    before_filter :initialize_vars
    before_filter :is_admin_user , :only => [:create,:update,:destroy]
  end

  def initialize_vars
  	
  end

  def is_admin_user
  	not_found("You don't have sufficient privileges to complete that action") if !current_signed_in_user.is_admin?
  end

  def create
  	@product = permitted_params[:product]
  	@product.resource_id = lookup_resource.id.to_s
    @product.resource_class = lookup_resource.class.name
    @product = add_signed_in_resource(@product)
  	@product.save
  	respond_with @product
  end

  def update

  end

  def index

  end

  def show

  end

  def destroy

  end

  def permitted_params
  	params.permit({:product => {:name,:price}})
  end

end