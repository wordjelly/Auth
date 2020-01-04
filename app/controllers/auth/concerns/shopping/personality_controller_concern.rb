module Auth::Concerns::Shopping::PersonalityControllerConcern

  extend ActiveSupport::Concern

  included do
    include Auth::Shopping::Personalities::PersonalitiesHelper
  end

  ##if an id is provided in the permitted params then tries to find that in the database, and makes a new cart item out of it.
  #if no id is provided then creates a new personality from the permitted params, but excluding the id key.
  #if a collection i.e plural resources is present in the permitted_params and its also there in our auth resources, then create a resource class and resource symbol out of it and assign resource as in the comments.
  def initialize_vars
    instantiate_shopping_classes

    @auth_shopping_personality_params = permitted_params.fetch(:personality,{})
    @auth_shopping_personality = params[:id] ? @auth_shopping_personality_class.find_self(params[:id],current_signed_in_resource) : @auth_shopping_personality_class.new(@auth_shopping_personality_params)
    
  end


  ##expects the product id, resource_id is the logged in resource, and quantity 
  def create
    ##ensure that the cart item is new
   
    check_for_create(@auth_shopping_personality)
    @auth_shopping_personality = add_owner_and_signed_in_resource(@auth_shopping_personality)
     
    @auth_shopping_personality.save

    respond_with @auth_shopping_personality
  end

  ##only permits the quantity to be changed, transaction id is internally assigned and can never be changed by the external world.
  def update
    check_for_update(@auth_shopping_personality)
    @auth_shopping_personality.assign_attributes(@auth_shopping_personality_params)
    @auth_shopping_personality = add_owner_and_signed_in_resource(@auth_shopping_personality)  
    @auth_shopping_personality.save
    puts @auth_shopping_personality.errors.full_messages.to_s
    respond_with @auth_shopping_personality
  end

  def show
    not_found if @auth_shopping_personality.nil?
    respond_with @auth_shopping_personality 
  end

  ## will have to have this lookup resource part here.
  ## what if we want to create items for the user
  ## 
  def index
    @auth_shopping_personalities = @auth_shopping_personality_class.find_personalities({:resource => lookup_resource}).page 1
    respond_with @auth_shopping_personalities
  end


  ##can be removed.
  ##responds with 204, and empty response body, if all is ok.
  def destroy
    not_found if @auth_shopping_personality.nil?
    @auth_shopping_personality.destroy
    respond_with @auth_shopping_personality
  end

  def search
    args = {:query_string => params[:query_string]}
    query_clause = Auth::Search::Main.es_six_finalize_search_query_clause(args)
    @search_results = Auth.configuration.personality_class.constantize.es.search(query_clause,{:wrapper => :load}).results
    respond_to do |format|
      ## with js.
      format.js do 
        render :partial => "search", locals: {search_results: @search_results, suggestions: []}
      end
      format.json do 
        render json: @search_results.to_json
      end
    end
  end


  ## this permitted params is overridden in the dummy app, and as a result throws unpermitted parameters for the daughter app parameters, even though they are subsequently permitted, since super is called first.
  def permitted_params

    params.permit({personality: [:date_of_birth, :fullname, :sex, :referred_by, :referrer_contact_number]},:id, :query_string)
    
  end

end
