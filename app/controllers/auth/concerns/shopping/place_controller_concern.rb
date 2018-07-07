module Auth::Concerns::Shopping::PlaceControllerConcern

  extend ActiveSupport::Concern

  included do
      
    ## to be able to initialize a cart item from a product
    ## inside the create_multiple def.
    include Auth::Shopping::Places::PlacesHelper

  end

  

  ##if an id is provided in the permitted params then tries to find that in the database, and makes a new cart item out of it.
  #if no id is provided then creates a new place from the permitted params, but excluding the id key.
  #if a collection i.e plural resources is present in the permitted_params and its also there in our auth resources, then create a resource class and resource symbol out of it and assign resource as in the comments.
  def initialize_vars
    instantiate_shopping_classes

  
    @auth_shopping_place_params = permitted_params.fetch(:place,{})
    @auth_shopping_place = params[:id] ? @auth_shopping_place_class.find_self(params[:id],current_signed_in_resource) : @auth_shopping_place_class.new(@auth_shopping_place_params)
    
  end


  ##expects the product id, resource_id is the logged in resource, and quantity 
  def create
    ##ensure that the cart item is new
   
    check_for_create(@auth_shopping_place)
    @auth_shopping_place = add_owner_and_signed_in_resource(@auth_shopping_place)
     
    @auth_shopping_place.save

    respond_with @auth_shopping_place
  end

  ##only permits the quantity to be changed, transaction id is internally assigned and can never be changed by the external world.
  def update
    check_for_update(@auth_shopping_place)
    @auth_shopping_place.assign_attributes(@auth_shopping_place_params)
    @auth_shopping_place = add_owner_and_signed_in_resource(@auth_shopping_place)  
    @auth_shopping_place.save
    puts @auth_shopping_place.errors.full_messages.to_s
    respond_with @auth_shopping_place
  end

  def show
    not_found if @auth_shopping_place.nil?
    respond_with @auth_shopping_place 
  end

  ##should show those cart items which do not have a parent_id.
  ##since these are the pending cart items.
  ##all remaining cart items have already been assigned to carts
  def index
    @auth_shopping_places = @auth_shopping_place_class.find_places({:resource => lookup_resource}).page 1
    respond_with @auth_shopping_places
  end


  ##can be removed.
  ##responds with 204, and empty response body, if all is ok.
  def destroy
    not_found if @auth_shopping_place.nil?
    @auth_shopping_place.destroy
    respond_with @auth_shopping_place
  end

  def search
    args = {:query_string => params[:query_string]}
    query_clause = Auth::Search::Main.es_six_finalize_search_query_clause(args)
    @search_results = Auth.configuration.place_class.constantize.es.search(query_clause,{:wrapper => :load}).results
    respond_to do |format|
      ## with js.
      format.js do 
        render :partial => "search_result", locals: {search_results: @search_results, suggestions: []}
      end
      format.json do 
        render json: @search_results.to_json
      end
    end
  end

  ## this permitted params is overridden in the dummy app, and as a result throws unpermitted parameters for the daughter app parameters, even though they are subsequently permitted, since super is called first.
  def permitted_params

    params.permit({place: [:full_address, :unit_number, :building, :street, :pin_code, :city, :country_state, :country, :latitude, :longitude]},:id,:query_string)
    

  end

end

